Skip to content

Jenkins
timer-app-pipeline
#7
Console Output
Search
Manage Jenkins
Status
Changes
Console Output
Edit Build Information
Timings
Pipeline Overview
Thread Dump
Pause/resume
Replay
Pipeline Steps
Workspaces
Previous Build
In progressIn progressIn progressIn progressIn progressIn progressIn progressIn progressIn progressIn progressIn progressIn progressIn progressIn progressIn progressIn progressIn progressIn progressIn progressIn progressIn progressIn progressIn progressIn progress
Console Output
Progress:
Cancel
Download

Copy
View as plain text
Started by user unknown or anonymous
Obtained Jenkinsfile from git https://github.com/tharunK03/TaskTImer-React.git
[Pipeline] Start of Pipeline
[Pipeline] node
Running on Jenkins in /Users/tharun/.jenkins/workspace/timer-app-pipeline
[Pipeline] {
[Pipeline] stage
[Pipeline] { (Declarative: Checkout SCM)
[Pipeline] checkout
The recommended git tool is: git
using credential github-creds
Cloning the remote Git repository
Cloning repository https://github.com/tharunK03/TaskTImer-React.git
 > git init /Users/tharun/.jenkins/workspace/timer-app-pipeline # timeout=10
Fetching upstream changes from https://github.com/tharunK03/TaskTImer-React.git
 > git --version # timeout=10
 > git --version # 'git version 2.49.0'
using GIT_ASKPASS to set credentials 
 > git fetch --tags --force --progress -- https://github.com/tharunK03/TaskTImer-React.git +refs/heads/*:refs/remotes/origin/* # timeout=10
 > git config remote.origin.url https://github.com/tharunK03/TaskTImer-React.git # timeout=10
 > git config --add remote.origin.fetch +refs/heads/*:refs/remotes/origin/* # timeout=10
Avoid second fetch
 > git rev-parse origin/main^{commit} # timeout=10
Checking out Revision 102f0f6ace5e05c2c0f031b852ee8c56244975ac (origin/main)
 > git config core.sparsecheckout # timeout=10
 > git checkout -f 102f0f6ace5e05c2c0f031b852ee8c56244975ac # timeout=10
Commit message: "🔧 Fixed pod selection in smoke test - now gets newest running pod"
 > git rev-list --no-walk 5b58c7f723beb9848c53a2c0ecf1467505a7b6c9 # timeout=10
[Pipeline] }
[Pipeline] // stage
[Pipeline] withEnv
[Pipeline] {
[Pipeline] withCredentials
Masking supported pattern matches of $KUBECONFIG
[Pipeline] {
[Pipeline] withEnv
[Pipeline] {
[Pipeline] stage
[Pipeline] { (Checkout)
[Pipeline] checkout
The recommended git tool is: git
using credential github-creds
 > git rev-parse --resolve-git-dir /Users/tharun/.jenkins/workspace/timer-app-pipeline/.git # timeout=10
Fetching changes from the remote Git repository
 > git config remote.origin.url https://github.com/tharunK03/TaskTImer-React.git # timeout=10
Fetching upstream changes from https://github.com/tharunK03/TaskTImer-React.git
 > git --version # timeout=10
 > git --version # 'git version 2.49.0'
using GIT_ASKPASS to set credentials 
 > git fetch --tags --force --progress -- https://github.com/tharunK03/TaskTImer-React.git +refs/heads/*:refs/remotes/origin/* # timeout=10
 > git rev-parse origin/main^{commit} # timeout=10
Checking out Revision 102f0f6ace5e05c2c0f031b852ee8c56244975ac (origin/main)
 > git config core.sparsecheckout # timeout=10
 > git checkout -f 102f0f6ace5e05c2c0f031b852ee8c56244975ac # timeout=10
Commit message: "🔧 Fixed pod selection in smoke test - now gets newest running pod"
[Pipeline] script
[Pipeline] {
[Pipeline] sh
+ git rev-parse --short HEAD
[Pipeline] }
[Pipeline] // script
[Pipeline] }
[Pipeline] // stage
[Pipeline] stage
[Pipeline] { (Build Docker Image)
[Pipeline] script
[Pipeline] {
[Pipeline] sh
++ minikube docker-env
+ eval export 'DOCKER_TLS_VERIFY="1"' export 'DOCKER_HOST="tcp://127.0.0.1:51434"' export 'DOCKER_CERT_PATH="/Users/tharun/.minikube/certs"' export 'MINIKUBE_ACTIVE_DOCKERD="minikube"' '#' To point your shell to 'minikube'\''s' docker-daemon, run: '#' eval '$(minikube' -p minikube 'docker-env)'
++ export DOCKER_TLS_VERIFY=1 export DOCKER_HOST=tcp://127.0.0.1:51434 export DOCKER_CERT_PATH=/Users/tharun/.minikube/certs export MINIKUBE_ACTIVE_DOCKERD=minikube
++ DOCKER_TLS_VERIFY=1
++ DOCKER_HOST=tcp://127.0.0.1:51434
++ DOCKER_CERT_PATH=/Users/tharun/.minikube/certs
++ MINIKUBE_ACTIVE_DOCKERD=minikube
+ docker build -t timer-app:7 .
#0 building with "default" instance using docker driver

#1 [internal] load build definition from Dockerfile
#1 transferring dockerfile: 711B 0.0s done
#1 DONE 0.0s

#2 [internal] load metadata for docker.io/library/node:20-alpine
#2 ...

#3 [auth] library/node:pull token for registry-1.docker.io
#3 DONE 0.0s

#4 [auth] library/nginx:pull token for registry-1.docker.io
#4 DONE 0.0s

#5 [internal] load metadata for docker.io/library/nginx:alpine
#5 DONE 1.7s

#2 [internal] load metadata for docker.io/library/node:20-alpine
#2 DONE 1.8s

#6 [internal] load .dockerignore
#6 transferring context: 135B 0.0s done
#6 DONE 0.0s

#7 [builder 1/7] FROM docker.io/library/node:20-alpine@sha256:6178e78b972f79c335df281f4b7674a2d85071aae2af020ffa39f0a770265435
#7 DONE 0.0s

#8 [stage-1 1/3] FROM docker.io/library/nginx:alpine@sha256:61e01287e546aac28a3f56839c136b31f590273f3b41187a36f46f6a03bbfe22
#8 DONE 0.0s

#9 [internal] load build context
#9 transferring context: 300.17kB 0.0s done
#9 DONE 0.1s

#10 [builder 2/7] WORKDIR /app
#10 CACHED

#11 [builder 3/7] COPY package*.json ./
#11 CACHED

#12 [builder 4/7] RUN npm ci
#12 CACHED

#13 [builder 5/7] COPY . .
#13 DONE 0.1s

#14 [builder 6/7] RUN rm -rf node_modules package-lock.json && npm install
#14 46.83 
#14 46.83 added 195 packages, and audited 196 packages in 45s
#14 46.83 
#14 46.83 50 packages are looking for funding
#14 46.83   run `npm fund` for details
#14 46.83 
#14 46.83 found 0 vulnerabilities
#14 DONE 47.2s

#15 [builder 7/7] RUN npm run build
#15 0.553 
#15 0.553 > my-app@0.0.0 build
#15 0.553 > tsc -b && vite build
#15 0.553 
#15 4.216 rolldown-vite v7.1.14 building for production...
#15 4.257 [2K
transforming...[32m✓[39m 27 modules transformed.
#15 4.416 rendering chunks...
#15 4.456 computing gzip size...
#15 4.461 [2mdist/[22m[32mindex.html                 [39m[1m[2m  0.45 kB[22m[22m[2m │ gzip:  0.29 kB[22m
#15 4.461 [2mdist/[22m[2massets/[22m[35mindex-DFKLJWTz.css  [39m[1m[2m 26.72 kB[22m[22m[2m │ gzip:  5.72 kB[22m
#15 4.461 [2mdist/[22m[2massets/[22m[36mindex-Cwhp330-.js   [39m[1m[2m202.45 kB[22m[22m[2m │ gzip: 64.19 kB[22m
#15 4.461 ✓ built in 244ms
#15 DONE 4.5s

#16 [stage-1 2/3] COPY --from=builder /app/dist /usr/share/nginx/html
#16 CACHED

#17 [stage-1 3/3] COPY nginx.conf /etc/nginx/conf.d/default.conf
#17 CACHED

#18 exporting to image
#18 exporting layers done
#18 writing image sha256:8918e94f9050e34e235f6e90da80b57193080f39f3577efa1d36ec0ea0a1e26b done
#18 naming to docker.io/library/timer-app:7 done
#18 DONE 0.0s

View build details: docker-desktop://dashboard/build/default/default/ndnrfyu3jqhgejpk7p267zty5
+ docker build -t timer-app:latest .
#0 building with "default" instance using docker driver

#1 [internal] load build definition from Dockerfile
#1 transferring dockerfile: 711B done
#1 DONE 0.0s

#2 [internal] load metadata for docker.io/library/nginx:alpine
#2 ...

#3 [internal] load metadata for docker.io/library/node:20-alpine
#3 DONE 1.0s

#2 [internal] load metadata for docker.io/library/nginx:alpine
#2 DONE 1.0s

#4 [internal] load .dockerignore
#4 transferring context: 135B done
#4 DONE 0.0s

#5 [builder 1/7] FROM docker.io/library/node:20-alpine@sha256:6178e78b972f79c335df281f4b7674a2d85071aae2af020ffa39f0a770265435
#5 DONE 0.0s

#6 [stage-1 1/3] FROM docker.io/library/nginx:alpine@sha256:61e01287e546aac28a3f56839c136b31f590273f3b41187a36f46f6a03bbfe22
#6 DONE 0.0s

#7 [internal] load build context
#7 transferring context: 5.82kB 0.0s done
#7 DONE 0.0s

#8 [builder 3/7] COPY package*.json ./
#8 CACHED

#9 [builder 7/7] RUN npm run build
#9 CACHED

#10 [builder 4/7] RUN npm ci
#10 CACHED

#11 [stage-1 2/3] COPY --from=builder /app/dist /usr/share/nginx/html
#11 CACHED

#12 [builder 5/7] COPY . .
#12 CACHED

#13 [builder 2/7] WORKDIR /app
#13 CACHED

#14 [builder 6/7] RUN rm -rf node_modules package-lock.json && npm install
#14 CACHED

#15 [stage-1 3/3] COPY nginx.conf /etc/nginx/conf.d/default.conf
#15 CACHED

#16 exporting to image
#16 exporting layers done
#16 writing image sha256:8918e94f9050e34e235f6e90da80b57193080f39f3577efa1d36ec0ea0a1e26b done
#16 naming to docker.io/library/timer-app:latest done
#16 DONE 0.0s

View build details: docker-desktop://dashboard/build/default/default/oawipy4uhts2rd1cgooykaq7s
[Pipeline] }
[Pipeline] // script
[Pipeline] }
[Pipeline] // stage
[Pipeline] stage
[Pipeline] { (Prepare Manifests)
[Pipeline] script
[Pipeline] {
[Pipeline] sh
+ cp k8s/kustomization.yaml k8s/kustomization.yaml.bak
+ sed -i '' 's/newTag: .*/newTag: "7"/' k8s/kustomization.yaml
+ echo 'Updated kustomization.yaml:'
Updated kustomization.yaml:
+ grep newTag k8s/kustomization.yaml
  newTag: "7"
[Pipeline] sh
+ kubectl apply -k k8s/
# Warning: 'commonLabels' is deprecated. Please use 'labels' instead. Run 'kustomize edit fix' to update your Kustomization automatically.
namespace/timer-app unchanged
configmap/timer-app-config unchanged
service/timer-app-service unchanged
deployment.apps/timer-app-blue configured
deployment.apps/timer-app-green configured
horizontalpodautoscaler.autoscaling/timer-app-blue-hpa unchanged
horizontalpodautoscaler.autoscaling/timer-app-green-hpa unchanged
ingress.networking.k8s.io/timer-app-ingress unchanged
[Pipeline] }
[Pipeline] // script
[Pipeline] }
[Pipeline] // stage
[Pipeline] stage
[Pipeline] { (Blue-Green Deploy)
[Pipeline] script
[Pipeline] {
[Pipeline] sh
+ kubectl get service timer-app-service -n timer-app -o 'jsonpath={.spec.selector.track}'
[Pipeline] echo
Active color: blue -> Target color: green
[Pipeline] sh
+ kubectl set image deployment/timer-app-green timer-app=timer-app:7 -n timer-app
+ kubectl rollout status deployment/timer-app-green -n timer-app --timeout=300s
Waiting for deployment "timer-app-green" rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for deployment "timer-app-green" rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for deployment "timer-app-green" rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for deployment "timer-app-green" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "timer-app-green" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "timer-app-green" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "timer-app-green" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "timer-app-green" rollout to finish: 1 old replicas are pending termination...
deployment "timer-app-green" successfully rolled out
+ kubectl wait --for=condition=available deployment/timer-app-green -n timer-app --timeout=300s
deployment.apps/timer-app-green condition met
+ kubectl wait --for=condition=ready pod -l app=timer-app,track=green -n timer-app --timeout=300s
pod/timer-app-green-5ddd556bc9-dwptl condition met
pod/timer-app-green-7bc8748c8f-bclxx condition met
pod/timer-app-green-7bc8748c8f-bq7n7 condition met
pod/timer-app-green-7bc8748c8f-r8n8z condition met
[Pipeline] }
[Pipeline] // script
[Pipeline] }
[Pipeline] // stage
[Pipeline] stage
[Pipeline] { (Smoke Test New Color)
[Pipeline] script
[Pipeline] {
[Pipeline] sh
+ set -e
+ echo 'Waiting for green pods to be ready...'
Waiting for green pods to be ready...
+ kubectl wait --for=condition=ready pod -l app=timer-app,track=green -n timer-app --timeout=60s
pod/timer-app-green-7bc8748c8f-bclxx condition met
pod/timer-app-green-7bc8748c8f-bq7n7 condition met
pod/timer-app-green-7bc8748c8f-r8n8z condition met
++ kubectl get pods -n timer-app -l app=timer-app,track=green --field-selector=status.phase=Running -o 'jsonpath={.items[-1].metadata.name}'
+ POD_NAME=timer-app-green-7bc8748c8f-r8n8z
+ echo 'Testing pod: timer-app-green-7bc8748c8f-r8n8z'
Testing pod: timer-app-green-7bc8748c8f-r8n8z
+ kubectl get pod timer-app-green-7bc8748c8f-r8n8z -n timer-app
NAME                               READY   STATUS    RESTARTS   AGE
timer-app-green-7bc8748c8f-r8n8z   1/1     Running   0          12s
+ PF_PID=1460
+ echo 'Port-forward started with PID: 1460'
Port-forward started with PID: 1460
+ sleep 15
+ kubectl port-forward -n timer-app pod/timer-app-green-7bc8748c8f-r8n8z 3001:80
+ set +e
+ curl -f http://localhost:3001 --connect-timeout 10 --max-time 30
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed

  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
curl: (52) Empty reply from server
+ STATUS=52
+ set -e
+ kill 1460
+ true
+ wait 1460
+ true
+ echo 'Smoke test status: 52'
Smoke test status: 52
+ '[' 52 -ne 0 ']'
+ echo 'Smoke test failed with status: 52'
Smoke test failed with status: 52
+ exit 52
[Pipeline] }
[Pipeline] // script
[Pipeline] }
[Pipeline] // stage
[Pipeline] stage
[Pipeline] { (Switch Traffic)
Stage "Switch Traffic" skipped due to earlier failure(s)
[Pipeline] getContext
[Pipeline] }
[Pipeline] // stage
[Pipeline] stage
[Pipeline] { (Post-Deployment Health Check)
Stage "Post-Deployment Health Check" skipped due to earlier failure(s)
[Pipeline] getContext
[Pipeline] }
[Pipeline] // stage
[Pipeline] stage
[Pipeline] { (Housekeeping)
Stage "Housekeeping" skipped due to earlier failure(s)
[Pipeline] getContext
[Pipeline] }
[Pipeline] // stage
[Pipeline] stage
[Pipeline] { (Declarative: Post Actions)
[Pipeline] script
[Pipeline] {
[Pipeline] cleanWs
[WS-CLEANUP] Deleting project workspace...
[WS-CLEANUP] Deferred wipeout is used...
[WS-CLEANUP] done
[Pipeline] }
[Pipeline] // script
[Pipeline] script
[Pipeline] {
[Pipeline] echo
❌ Pipeline failed!
[Pipeline] sh
+ kubectl patch service timer-app-service -n timer-app --type=merge -p '{"spec":{"selector":{"app":"timer-app","track":"blue"}}}'
service/timer-app-service patched (no change)
+ kubectl rollout undo deployment/timer-app-green -n timer-app
deployment.apps/timer-app-green rolled back
[Pipeline] }
[Pipeline] // script
[Pipeline] }
[Pipeline] // stage
[Pipeline] }
[Pipeline] // withEnv
[Pipeline] }
[Pipeline] // withCredentials
[Pipeline] }
[Pipeline] // withEnv
[Pipeline] }
[Pipeline] // node
[Pipeline] End of Pipeline
ERROR: script returned exit code 52
Finished: FAILURE
REST API
Jenkins 2.528.1pipeline {
    agent any

    environment {
        DOCKER_REGISTRY = 'tharunk03'
        IMAGE_NAME = 'timer-app'
        IMAGE_TAG = "${BUILD_NUMBER}"
        KUBECONFIG = credentials('kubeconfig')
        KUBE_NAMESPACE = 'timer-app'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.GIT_COMMIT_SHORT = sh(
                        script: "git rev-parse --short HEAD",
                        returnStdout: true
                    ).trim()
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh """
                        eval \$(minikube docker-env)
                        docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
                        docker build -t ${IMAGE_NAME}:latest .
                    """
                }
            }
        }

        stage('Prepare Manifests') {
            steps {
                script {
                    sh """
                        # Create a backup
                        cp k8s/kustomization.yaml k8s/kustomization.yaml.bak
                        
                        # Replace newTag with quoted version
                        sed -i '' 's/newTag: .*/newTag: "'${IMAGE_TAG}'"/' k8s/kustomization.yaml
                        
                        # Verify the change
                        echo "Updated kustomization.yaml:"
                        grep newTag k8s/kustomization.yaml
                    """
                    sh "kubectl apply -k k8s/"
                }
            }
        }

        stage('Blue-Green Deploy') {
            steps {
                script {
                    def currentColor = sh(
                        script: "kubectl get service timer-app-service -n ${KUBE_NAMESPACE} -o jsonpath='{.spec.selector.track}' 2>/dev/null || true",
                        returnStdout: true
                    ).trim()

                    if (!currentColor) {
                        currentColor = 'blue'
                    }

                    env.ACTIVE_COLOR = currentColor
                    env.TARGET_COLOR = currentColor == 'blue' ? 'green' : 'blue'

                    echo "Active color: ${env.ACTIVE_COLOR} -> Target color: ${env.TARGET_COLOR}"

                    def targetDeployment = "timer-app-${env.TARGET_COLOR}"

                    sh """
                        kubectl set image deployment/${targetDeployment} timer-app=${IMAGE_NAME}:${IMAGE_TAG} -n ${KUBE_NAMESPACE}
                        kubectl rollout status deployment/${targetDeployment} -n ${KUBE_NAMESPACE} --timeout=300s
                        kubectl wait --for=condition=available deployment/${targetDeployment} -n ${KUBE_NAMESPACE} --timeout=300s
                        kubectl wait --for=condition=ready pod -l app=timer-app,track=${env.TARGET_COLOR} -n ${KUBE_NAMESPACE} --timeout=300s
                    """
                }
            }
        }

        stage('Smoke Test New Color') {
            steps {
                script {
                    sh """
                        set -e
                        
                        # Wait for pods to be ready and get a running pod
                        echo "Waiting for ${env.TARGET_COLOR} pods to be ready..."
                        kubectl wait --for=condition=ready pod -l app=timer-app,track=${env.TARGET_COLOR} -n ${KUBE_NAMESPACE} --timeout=60s
                        
                        # Get the newest running pod
                        POD_NAME=\$(kubectl get pods -n ${KUBE_NAMESPACE} -l app=timer-app,track=${env.TARGET_COLOR} --field-selector=status.phase=Running -o jsonpath='{.items[-1].metadata.name}')
                        echo "Testing pod: \$POD_NAME"
                        
                        # Verify pod is actually running and ready
                        kubectl get pod \$POD_NAME -n ${KUBE_NAMESPACE}
                        
                        # Wait additional time for pod to be fully ready to serve requests
                        echo "Waiting for pod to be fully ready to serve requests..."
                        sleep 30
                        
                        # Start port-forward in background
                        kubectl port-forward -n ${KUBE_NAMESPACE} pod/\$POD_NAME 3001:80 >/tmp/timer-app-bluegreen-\${BUILD_NUMBER}.log 2>&1 &
                        PF_PID=\$!
                        echo "Port-forward started with PID: \$PF_PID"
                        
                        # Wait for port-forward to be ready
                        sleep 20
                        
                        # Test the application with retries
                        echo "Testing application with retries..."
                        set +e
                        for i in {1..3}; do
                            echo "Attempt \$i/3..."
                            curl -f http://localhost:3001 --connect-timeout 15 --max-time 30
                            STATUS=\$?
                            if [ \$STATUS -eq 0 ]; then
                                echo "Test successful on attempt \$i"
                                break
                            else
                                echo "Test failed on attempt \$i with status: \$STATUS"
                                if [ \$i -lt 3 ]; then
                                    echo "Retrying in 10 seconds..."
                                    sleep 10
                                fi
                            fi
                        done
                        set -e
                        
                        # Clean up port-forward
                        kill \$PF_PID 2>/dev/null || true
                        wait \$PF_PID 2>/dev/null || true
                        
                        echo "Smoke test status: \$STATUS"
                        if [ \$STATUS -ne 0 ]; then
                            echo "Smoke test failed with status: \$STATUS"
                            exit \$STATUS
                        fi
                        echo "Smoke test passed!"
                    """
                }
            }
        }

        stage('Switch Traffic') {
            steps {
                script {
                    sh """
                        kubectl patch service timer-app-service -n ${KUBE_NAMESPACE} --type=merge -p '{"spec":{"selector":{"app":"timer-app","track":"${env.TARGET_COLOR}"}}}'
                    """

                    if (env.ACTIVE_COLOR && env.ACTIVE_COLOR != env.TARGET_COLOR) {
                        sh """
                            kubectl scale deployment/timer-app-${env.ACTIVE_COLOR} -n ${KUBE_NAMESPACE} --replicas=1
                        """
                    }
                }
            }
        }

        stage('Post-Deployment Health Check') {
            steps {
                script {
                    sh """
                        set -e
                        echo "Starting post-deployment health check..."
                        
                        # Start port-forward in background
                        kubectl port-forward -n ${KUBE_NAMESPACE} service/timer-app-service 3000:80 >/tmp/timer-app-service-\${BUILD_NUMBER}.log 2>&1 &
                        PF_PID=\$!
                        echo "Service port-forward started with PID: \$PF_PID"
                        
                        # Wait for port-forward to be ready
                        sleep 15
                        
                        # Test the application
                        set +e
                        curl -f http://localhost:3000 --connect-timeout 10 --max-time 30
                        STATUS=\$?
                        set -e
                        
                        # Clean up port-forward
                        kill \$PF_PID 2>/dev/null || true
                        wait \$PF_PID 2>/dev/null || true
                        
                        echo "Health check status: \$STATUS"
                        if [ \$STATUS -ne 0 ]; then
                            echo "Health check failed with status: \$STATUS"
                            exit \$STATUS
                        fi
                        echo "Health check passed!"
                    """
                }
            }
        }

        stage('Housekeeping') {
            steps {
                script {
                    sh """
                        eval \$(minikube docker-env)
                        docker image prune -f
                    """
                }
            }
        }
    }

    post {
        always {
            script {
                try {
                    cleanWs()
                } catch (Exception e) {
                    echo "Warning: Could not clean workspace: ${e.getMessage()}"
                }
            }
        }

        success {
            script {
                try {
                    echo "✅ Pipeline completed successfully!"
                    if (env.TARGET_COLOR) {
                        echo "🚀 Timer app deployed to ${env.TARGET_COLOR} with image: ${DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
                    } else {
                        echo "🚀 Timer app deployed successfully!"
                    }
                } catch (Exception e) {
                    echo "✅ Pipeline completed successfully!"
                }
            }
        }

        failure {
            script {
                try {
                    echo "❌ Pipeline failed!"
                    if (env.ACTIVE_COLOR && env.ACTIVE_COLOR.trim() && env.TARGET_COLOR && env.TARGET_COLOR.trim()) {
                        sh """
                            kubectl patch service timer-app-service -n ${KUBE_NAMESPACE} --type=merge -p '{"spec":{"selector":{"app":"timer-app","track":"${env.ACTIVE_COLOR}"}}}' || true
                            kubectl rollout undo deployment/timer-app-${env.TARGET_COLOR} -n ${KUBE_NAMESPACE} || true
                        """
                    }
                } catch (Exception e) {
                    echo "❌ Pipeline failed! Error: ${e.getMessage()}"
                }
            }
        }
    }
}
