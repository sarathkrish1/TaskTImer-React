CI/CD for Timer App (Jenkins -> Docker -> Kubernetes)

Overview
--------
This document explains how to wire Jenkins to build the Docker image for the Timer React app, push it to a container registry, and perform a blue/green deployment to Kubernetes using the `Jenkinsfile` in the repo root.

What the pipeline does
----------------------
- Checkout code from SCM
- Build Docker image and tag with `${BUILD_NUMBER}` and `latest`
- Login to container registry and push images
- Use a kubeconfig (Jenkins secret file) to run `kubectl` commands
- Perform a blue/green update by setting the new image on the target deployment, waiting for rollout, running a smoke test, and patching the service selector to switch traffic
- On failure the pipeline attempts a rollback (patch service back and `kubectl rollout undo`)

Files of interest
-----------------
- `Jenkinsfile` - Declarative pipeline that does build → push → deploy
- `Dockerfile` - Multi-stage build for the React app
- `scripts/deploy.sh` - Helper script for local/manual runs (can build/push/deploy)
- `k8s/` - Kubernetes manifests (blue/green deployments, service, HPA, ingress)

Jenkins setup (required credentials and job config)
--------------------------------------------------
1) Credentials
   - Docker registry credentials (username/password)
     - Kind: Username with password
     - ID: dockerhub-creds (or change the ID in the `Jenkinsfile`)
   - Kubeconfig
     - Kind: Secret file
     - ID: kubeconfig
     - Upload a kubeconfig file that has permission to `apply`, `set image`, `rollout` and `patch` in the `timer-app` namespace (or cluster-admin for testing)

2) Job configuration
   - Create a Pipeline or Multibranch Pipeline job and point it to this repository.
   - Use the repository `Jenkinsfile` (pipeline as code).
   - Optionally set environment variables in the job (or change in-file defaults):
     - `REGISTRY` — e.g., `docker.io/<youruser>`
     - `TARGET_COLOR` — `green` (default) or `blue`

3) Jenkins agents
   - Ensure the agent that executes the job has `docker`, `kubectl`, and `git` installed.
   - The agent needs network access to the container registry and the Kubernetes API server referenced by the kubeconfig.

Plugins (recommended)
---------------------
- Pipeline (workflow)
- Credentials Binding Plugin
- Docker Pipeline (optional — for pipeline-native docker usage)
- Git plugin
- (Optional) Kubernetes CLI plugin / Blue Ocean

How to test locally (recommended: Git Bash or WSL on Windows)
-------------------------------------------------------------
Notes: The repo scripts and example commands are shell (bash) - on Windows use Git Bash or WSL.

1) Build the Docker image locally

```bash
REGISTRY="docker.io/youruser"
IMAGE_NAME="timer-app"
BUILD_NUMBER="localtest"

docker build -t ${REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER} -t ${REGISTRY}/${IMAGE_NAME}:latest .
```

2) Push images to registry (login first)

```bash
docker login docker.io
docker push ${REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER}
docker push ${REGISTRY}/${IMAGE_NAME}:latest
```

3) Deploy to your Kubernetes cluster using the helper script

Make sure your kubeconfig is pointing to the cluster (or supply KUBECONFIG). Example:

```bash
# set env and run full pipeline locally
DOCKER_REGISTRY=${REGISTRY} IMAGE_NAME=${IMAGE_NAME} BUILD_NUMBER=${BUILD_NUMBER} NAMESPACE=timer-app ./scripts/deploy.sh full
```

Or use kubectl directly:

```bash
# update the green deployment to the new image
KUBECONFIG=/path/to/kubeconfig kubectl set image deployment/timer-app-green timer-app=${REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER} -n timer-app
KUBECONFIG=/path/to/kubeconfig kubectl rollout status deployment/timer-app-green -n timer-app --timeout=300s
# pick a pod and test
POD=$(KUBECONFIG=/path/to/kubeconfig kubectl get pods -n timer-app -l app=timer-app,track=green -o jsonpath='{.items[-1].metadata.name}')
KUBECONFIG=/path/to/kubeconfig kubectl exec -n timer-app $POD -- curl -f http://localhost:80
# switch traffic
KUBECONFIG=/path/to/kubeconfig kubectl patch service timer-app-service -n timer-app --type=merge -p '{"spec":{"selector":{"app":"timer-app","track":"green"}}}'
```

Troubleshooting tips
--------------------
- If `kubectl` cannot reach the cluster, verify your kubeconfig and network access. Use `kubectl --kubeconfig=/path get nodes` to test.
- If Docker push fails, ensure your registry value is correct and the credentials are valid.
- If pods never become ready, check `kubectl describe pod <name>` and `kubectl logs <pod>` for errors (node resource limits, missing files, env vars, etc.).

Blue-Green deployment strategy
------------------------------
This repository uses a blue-green deployment model:

- Two deployments exist: `timer-app-blue` and `timer-app-green`. Each has label `track: blue` or `track: green` respectively.
- The `timer-app-service` service selects pods using the `track` label (initially set to `blue` in the manifests).
- The pipeline detects which color is currently active (by reading `.spec.selector.track` from the service). It deploys the new image to the opposite color (the "target" color).
- After deploying and verifying the target pods are healthy (rollout status and a smoke test), the pipeline patches the service selector to point to the target color, effectively switching live traffic.
- If smoke tests fail or other steps fail, the pipeline attempts to rollback by patching the service back to the previous color and undoing the rollout on the target deployment.

Verification and safety
-----------------------
- The pipeline uses `kubectl rollout status` and `kubectl wait` to ensure new pods are ready before switching traffic.
- Smoke tests run by executing `curl` inside a pod of the target deployment. You can extend this to:
  - Call the service via `kubectl port-forward` and test using `localhost`, or
  - Hit the ingress endpoint if the cluster ingress is available in CI.
- Use immutable tagging (commit SHA + build number) for easier rollback and traceability.

Making the Jenkins pipeline safer
--------------------------------
- The `Jenkinsfile` now automatically detects the active color and selects the opposite as the target.
- Use immutable tags (e.g., commit SHA) in addition to `${BUILD_NUMBER}` to help traceability.
- Run smoke tests that call the application endpoint via the cluster Ingress or Service (the pipeline currently runs a `kubectl exec` -> `curl` inside the pod). You can extend to run end-to-end tests through the ingress URL.

Rollback behavior
-----------------
- On pipeline failure the `post` section attempts to patch the service back to the previous color and run `kubectl rollout undo` for the updated deployment. Adjust the logic if you prefer a different rollback strategy (e.g., keep the old deployment running and reroute traffic back).

Next steps (suggested)
----------------------
- Add a job parameter for `REGISTRY` and `TARGET_COLOR` (optional).
- Add end-to-end smoke tests that exercise the application via the ingress URL.
- Add more observability (probe endpoints, request traces, Canary metrics) to base deployment decisions on metrics.

If you want, I will now:
- run a quick Docker build locally to validate the `Dockerfile`, or
- further enhance the smoke test to prefer service/ingress checks over pod exec.

