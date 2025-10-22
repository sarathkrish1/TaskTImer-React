# Kubernetes Deployment for Timer App

This directory contains Kubernetes manifests for deploying the Timer application.

## Files Overview

- `namespace.yaml` - Creates a dedicated namespace for the timer app
- `configmap.yaml` - Nginx configuration for the application
- `deployment.yaml` - Main application deployment with 3 replicas
- `service.yaml` - ClusterIP service to expose the application internally
- `ingress.yaml` - Ingress for external access (requires ingress controller)
- `hpa.yaml` - Horizontal Pod Autoscaler for automatic scaling
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
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml
kubectl apply -f k8s/hpa.yaml
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

# Check HPA
kubectl get hpa -n timer-app
```

## Accessing the Application

1. **Via Ingress**: Add `timer-app.local` to your `/etc/hosts` file pointing to your ingress controller IP
2. **Via Port Forward**: `kubectl port-forward -n timer-app service/timer-app-service 8080:80`
3. **Via NodePort**: Modify service.yaml to use NodePort type

## Scaling

The application will automatically scale based on CPU and memory usage:
- Min replicas: 2
- Max replicas: 10
- CPU target: 70%
- Memory target: 80%

## Monitoring

```bash
# View logs
kubectl logs -n timer-app deployment/timer-app-deployment

# Describe deployment
kubectl describe deployment -n timer-app timer-app-deployment

# Check events
kubectl get events -n timer-app
```
