# Complete Jenkins CI/CD Pipeline for Timer App

## 🚀 Overview

This repository contains a complete CI/CD pipeline setup for deploying a Dockerized React Timer application to Kubernetes using Jenkins.

## 📁 Project Structure

```
Timer/
├── src/                          # React application source
├── k8s/                          # Kubernetes manifests
│   ├── namespace.yaml
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── hpa.yaml
│   ├── configmap.yaml
│   └── kustomization.yaml
├── scripts/                      # Deployment scripts
│   ├── deploy.sh                 # Main deployment script
│   └── validate.sh               # Validation script
├── Dockerfile                    # Docker build configuration
├── docker-compose.yml            # Local Docker setup
├── Jenkinsfile                   # Jenkins pipeline definition
├── jenkins-setup.md              # Jenkins configuration guide
└── README.md                     # This file
```

## 🔧 Prerequisites

### Jenkins Setup
1. **Install Required Plugins:**
   - Docker Pipeline
   - Kubernetes CLI
   - Kubernetes Plugin
   - Git Plugin
   - Credentials Plugin

2. **Configure Credentials:**
   - `docker-registry-credentials` - Docker registry username/password
   - `kubeconfig` - Kubernetes configuration file

3. **Global Tools Configuration:**
   - Docker
   - kubectl
   - Git

### Infrastructure Requirements
- Kubernetes cluster (minikube, GKE, EKS, AKS, etc.)
- Docker registry (Docker Hub, ECR, GCR, etc.)
- Ingress controller (NGINX, Traefik, etc.)

## 🚀 Pipeline Stages

### 1. **Checkout**
- Clone repository
- Extract commit hash for tagging

### 2. **Build Docker Image**
- Build image with build number tag
- Build latest tag
- Multi-stage build for optimization

### 3. **Push Docker Image**
- Push to registry with authentication
- Tag with build number and latest

### 4. **Deploy to Kubernetes**
- Update image tag in kustomization
- Apply Kubernetes manifests
- Wait for rollout completion

### 5. **Health Check**
- Verify pod readiness
- Test application connectivity
- Validate deployment success

### 6. **Cleanup**
- Remove old Docker images
- Clean workspace

## 📋 Quick Start

### 1. Configure Environment Variables
```bash
export DOCKER_REGISTRY="your-registry.com"
export IMAGE_NAME="timer-app"
export NAMESPACE="timer-app"
```

### 2. Create Jenkins Pipeline
1. Go to Jenkins → New Item → Pipeline
2. Configure Git repository
3. Set Jenkinsfile path
4. Configure credentials

### 3. Run Pipeline
```bash
# Manual trigger or webhook
# Pipeline will automatically:
# - Build Docker image
# - Push to registry
# - Deploy to Kubernetes
# - Validate deployment
```

## 🛠️ Manual Deployment

### Using Scripts
```bash
# Full pipeline
./scripts/deploy.sh full

# Individual steps
./scripts/deploy.sh build
./scripts/deploy.sh push
./scripts/deploy.sh deploy
./scripts/deploy.sh health

# Validation
./scripts/validate.sh
```

### Using kubectl
```bash
# Deploy
kubectl apply -k k8s/

# Check status
kubectl get all -n timer-app

# Access app
kubectl port-forward -n timer-app service/timer-app-service 8080:80
```

## 📊 Monitoring & Troubleshooting

### Check Deployment Status
```bash
kubectl get all -n timer-app
kubectl describe deployment timer-app-deployment -n timer-app
kubectl get events -n timer-app
```

### View Logs
```bash
kubectl logs -n timer-app deployment/timer-app-deployment
kubectl logs -n timer-app -l app=timer-app
```

### Debug Issues
```bash
# Check pod status
kubectl get pods -n timer-app -o wide

# Describe pod for events
kubectl describe pod -n timer-app -l app=timer-app

# Test connectivity
kubectl run debug --image=busybox -it --rm -- nslookup timer-app-service.timer-app.svc.cluster.local
```

## 🔄 Rollback

### Automatic Rollback
Pipeline automatically rolls back on failure.

### Manual Rollback
```bash
kubectl rollout undo deployment/timer-app-deployment -n timer-app
kubectl rollout status deployment/timer-app-deployment -n timer-app
```

## 📈 Scaling

The deployment includes Horizontal Pod Autoscaler (HPA):
- **Min replicas:** 2
- **Max replicas:** 10
- **CPU threshold:** 70%
- **Memory threshold:** 80%

Monitor scaling:
```bash
kubectl get hpa -n timer-app
kubectl describe hpa timer-app-hpa -n timer-app
```

## 🔒 Security Features

- **Non-root containers**
- **Resource limits**
- **Security headers**
- **Network policies** (optional)
- **RBAC** (recommended)

## 🌐 Access Methods

### 1. Port Forward (Development)
```bash
kubectl port-forward -n timer-app service/timer-app-service 8080:80
# Access: http://localhost:8080
```

### 2. Ingress (Production)
```bash
# Add to /etc/hosts
echo "127.0.0.1 timer-app.local"

# Access: http://timer-app.local
```

### 3. NodePort (Testing)
Modify `service.yaml` to use NodePort type.

## 📝 Customization

### Environment Variables
Update `k8s/configmap.yaml` for environment-specific configurations.

### Resource Limits
Modify `k8s/deployment.yaml` for different resource requirements.

### Scaling Policies
Adjust `k8s/hpa.yaml` for different scaling behavior.

## 🚨 Troubleshooting

### Common Issues

1. **Docker Build Fails**
   - Check Dockerfile syntax
   - Verify Node.js version
   - Check dependencies

2. **Kubernetes Deployment Fails**
   - Verify kubeconfig
   - Check namespace
   - Validate YAML

3. **Health Check Fails**
   - Check pod logs
   - Verify service endpoints
   - Test connectivity

### Debug Commands
```bash
# Check all resources
kubectl get all -n timer-app

# Check events
kubectl get events -n timer-app --sort-by='.lastTimestamp'

# Check pod logs
kubectl logs -n timer-app -l app=timer-app --tail=100

# Check service endpoints
kubectl get endpoints -n timer-app
```

## 📞 Support

For issues or questions:
1. Check Jenkins pipeline logs
2. Review Kubernetes events
3. Validate deployment status
4. Check application logs

## 🎯 Next Steps

1. **Set up monitoring** (Prometheus, Grafana)
2. **Implement logging** (ELK stack)
3. **Add security scanning** (Trivy, Snyk)
4. **Configure notifications** (Slack, email)
5. **Set up staging environment**
6. **Implement blue-green deployments**