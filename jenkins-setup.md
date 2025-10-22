# Jenkins CI/CD Pipeline Configuration

## Prerequisites

### 1. Jenkins Plugins Required
Install these plugins in Jenkins:
- Docker Pipeline
- Kubernetes CLI
- Kubernetes Plugin
- Git Plugin
- Credentials Plugin

### 2. Credentials Setup
Create these credentials in Jenkins:

#### Docker Registry Credentials
- **ID**: `docker-registry-credentials`
- **Type**: Username with password
- **Username**: Your Docker registry username
- **Password**: Your Docker registry password/token

#### Kubernetes Config
- **ID**: `kubeconfig`
- **Type**: Secret file
- **File**: Upload your `~/.kube/config` file

### 3. Environment Variables
Set these in Jenkins Global Tool Configuration:

```bash
# Docker registry URL
DOCKER_REGISTRY=your-registry.com

# Kubernetes namespace
KUBE_NAMESPACE=timer-app

# Image name
IMAGE_NAME=timer-app
```

## Pipeline Stages

### 1. Checkout
- Clones the repository
- Gets short commit hash for tagging

### 2. Build Docker Image
- Builds Docker image with build number tag
- Builds latest tag
- Uses Dockerfile in project root

### 3. Push Docker Image
- Pushes both tagged and latest images to registry
- Uses Docker credentials for authentication

### 4. Deploy to Kubernetes
- Updates kustomization.yaml with new image tag
- Applies Kubernetes manifests
- Waits for deployment rollout

### 5. Health Check
- Waits for pods to be ready
- Tests application via port-forward
- Validates deployment success

### 6. Cleanup
- Removes old Docker images
- Cleans up workspace

## Deployment Commands

### Manual Deployment
```bash
# Build and push image
docker build -t your-registry.com/timer-app:latest .
docker push your-registry.com/timer-app:latest

# Deploy to Kubernetes
kubectl apply -k k8s/
kubectl rollout status deployment/timer-app-deployment -n timer-app
```

### Rollback
```bash
kubectl rollout undo deployment/timer-app-deployment -n timer-app
```

## Monitoring

### Check Deployment Status
```bash
kubectl get all -n timer-app
kubectl describe deployment timer-app-deployment -n timer-app
```

### View Logs
```bash
kubectl logs -n timer-app deployment/timer-app-deployment
kubectl logs -n timer-app -l app=timer-app
```

### Access Application
```bash
# Port forward
kubectl port-forward -n timer-app service/timer-app-service 8080:80

# Via ingress (if configured)
curl -H "Host: timer-app.local" http://your-ingress-ip/
```

## Troubleshooting

### Common Issues

1. **Docker Build Fails**
   - Check Dockerfile syntax
   - Verify Node.js version compatibility
   - Check for missing dependencies

2. **Kubernetes Deployment Fails**
   - Verify kubeconfig credentials
   - Check namespace exists
   - Validate YAML syntax

3. **Health Check Fails**
   - Check pod logs
   - Verify service endpoints
   - Test port-forward manually

### Debug Commands
```bash
# Check pod status
kubectl get pods -n timer-app -o wide

# Describe pod for events
kubectl describe pod -n timer-app -l app=timer-app

# Check service endpoints
kubectl get endpoints -n timer-app

# Test connectivity
kubectl run debug --image=busybox -it --rm -- nslookup timer-app-service.timer-app.svc.cluster.local
```

## Security Considerations

1. **Use Secrets for sensitive data**
2. **Implement RBAC for Kubernetes**
3. **Scan Docker images for vulnerabilities**
4. **Use non-root containers**
5. **Implement network policies**

## Scaling

The deployment includes HPA (Horizontal Pod Autoscaler):
- Min replicas: 2
- Max replicas: 10
- CPU threshold: 70%
- Memory threshold: 80%

Monitor scaling with:
```bash
kubectl get hpa -n timer-app
kubectl describe hpa timer-app-hpa -n timer-app
```
