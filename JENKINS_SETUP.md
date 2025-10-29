# Jenkins Setup for Blue-Green Deployment

## 1. Jenkins Installation and Configuration

### 1.1 Install Jenkins
```bash
# Add Jenkins repo and install
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update
sudo apt-get install jenkins

# Start Jenkins
sudo systemctl start jenkins
sudo systemctl status jenkins
```

### 1.2 Required Jenkins Plugins
Install these plugins via Jenkins > Manage Jenkins > Plugins:
- Docker Pipeline
- Kubernetes CLI
- Kubernetes
- Git
- Pipeline
- Blue Ocean (optional, for better UI)

### 1.3 Configure Credentials
1. **Docker Registry Credentials**
   - Go to Jenkins > Manage Jenkins > Credentials > System > Global credentials
   - Click "Add Credentials"
   - Kind: Username with password
   - ID: `dockerhub-creds`
   - Username: Your Docker Hub username
   - Password: Your Docker Hub password/token

2. **Kubernetes Configuration**
   - Go to Jenkins > Manage Jenkins > Credentials > System > Global credentials
   - Click "Add Credentials"
   - Kind: Secret file
   - ID: `kubeconfig`
   - File: Upload your kubeconfig file

## 2. Create Jenkins Pipeline

### 2.1 Create New Pipeline Job
1. Click "New Item" in Jenkins
2. Select "Pipeline"
3. Configure Source Code Management:
   - Git
   - Repository URL: Your repo URL
   - Credentials: Add your Git credentials if private
4. Script Path: `Jenkinsfile`

### 2.2 Configure Pipeline Parameters (Optional)
Add these parameters in the pipeline configuration:
- REGISTRY (String): Docker registry URL
- TARGET_COLOR (Choice): blue, green

## 3. Initial Deployment Setup

### 3.1 Create Kubernetes Namespace
```bash
kubectl create namespace timer-app
```

### 3.2 Create ConfigMap for Nginx
```bash
kubectl create configmap timer-app-config --from-file=nginx.conf -n timer-app
```

### 3.3 Deploy Initial Blue Version
```bash
# Apply Kubernetes manifests
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/deployment-blue.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/hpa-blue.yaml

# Verify deployment
kubectl get all -n timer-app
```

## 4. Test the Setup

### 4.1 Manual Deployment Test
```bash
# Build and push image
docker build -t your-registry/timer-app:test .
docker push your-registry/timer-app:test

# Update deployment
kubectl set image deployment/timer-app-blue timer-app=your-registry/timer-app:test -n timer-app
kubectl rollout status deployment/timer-app-blue -n timer-app
```

### 4.2 Test Jenkins Pipeline
1. Run the pipeline in Jenkins
2. Monitor the stages:
   - Checkout
   - Build
   - Push
   - Deploy to inactive color
   - Smoke test
   - Switch traffic
   - Verify

### 4.3 Verify Blue-Green Switch
```bash
# Check current color
kubectl get service timer-app-service -n timer-app -o jsonpath='{.spec.selector.track}'

# Check pods
kubectl get pods -n timer-app --show-labels
```

## 5. Monitoring Setup

### 5.1 Deploy Prometheus (Optional)
```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install prometheus prometheus-community/kube-prometheus-stack -n monitoring
```

### 5.2 Add Service Monitors
```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: timer-app
  namespace: monitoring
spec:
  selector:
    matchLabels:
      app: timer-app
  namespaceSelector:
    matchNames:
      - timer-app
  endpoints:
    - port: http
```

## 6. Troubleshooting

### 6.1 Common Issues
- **Image Pull Errors**: Check Docker credentials
- **Pod Pending**: Check node resources
- **Health Check Failures**: Verify app endpoint
- **Traffic Not Switching**: Check service selector

### 6.2 Useful Commands
```bash
# Check pod logs
kubectl logs -f deployment/timer-app-blue -n timer-app

# Check deployment status
kubectl describe deployment timer-app-blue -n timer-app

# Check service endpoints
kubectl get endpoints timer-app-service -n timer-app

# Force rollback
kubectl rollout undo deployment/timer-app-blue -n timer-app
```

## Next Steps

1. Set up monitoring dashboards
2. Configure alerting for deployment status
3. Add deployment metrics collection
4. Implement canary deployments
5. Add automated rollback triggers