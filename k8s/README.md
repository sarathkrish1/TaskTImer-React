# Kubernetes Deployment for Timer App

This directory contains Kubernetes manifests for deploying the Timer application.

## Files Overview

- `namespace.yaml` - Creates a dedicated namespace for the timer app
- `configmap.yaml` - Nginx configuration for the application
- `deployment-blue.yaml` - Blue deployment used for blue-green rollout
- `deployment-green.yaml` - Green deployment used for blue-green rollout
- `service.yaml` - ClusterIP service to expose the application internally
- `ingress.yaml` - Ingress for external access (requires ingress controller)
- `hpa-blue.yaml` - HPA configuration for the blue deployment
- `hpa-green.yaml` - HPA configuration for the green deployment
- `kustomization.yaml` - Kustomize configuration for easy deployment

## Prerequisites

1. Kubernetes cluster running
2. Ingress controller installed (e.g., NGINX Ingress Controller)
3. Docker image `timer-app:latest` available in your cluster's registry

## Deployment Commands

### Using kubectl directly:
```bash
# Apply all manifests
kubectl apply -f k8s/

# Or apply individually
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/deployment-blue.yaml
kubectl apply -f k8s/deployment-green.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml
kubectl apply -f k8s/hpa-blue.yaml
kubectl apply -f k8s/hpa-green.yaml
```

### Using Kustomize:
```bash
kubectl apply -k k8s/
```

## Verification

```bash
# Check deployment status
kubectl get deployments -n timer-app

# Check pods
kubectl get pods -n timer-app

# Check services
kubectl get services -n timer-app

# Check ingress
kubectl get ingress -n timer-app

# Check HPAs
kubectl get hpa -n timer-app
```

## Accessing the Application

1. **Via Ingress**: Add `timer-app.local` to your `/etc/hosts` file pointing to your ingress controller IP
2. **Via Port Forward**: `kubectl port-forward -n timer-app service/timer-app-service 8080:80`
3. **Via NodePort**: Modify service.yaml to use NodePort type

## Scaling

The application uses independent HPAs for the blue and green deployments:
- Min replicas: 2 (per colour)
- Max replicas: 10 (per colour)
- CPU target: 70%
- Memory target: 80%

## Monitoring

```bash
# View logs
kubectl logs -n timer-app deployment/timer-app-blue
kubectl logs -n timer-app deployment/timer-app-green

# Describe deployment
kubectl describe deployment -n timer-app timer-app-blue
kubectl describe deployment -n timer-app timer-app-green

# Check events
kubectl get events -n timer-app
```
