# Install required tools for Blue-Green deployment
Write-Host "Installing required tools for Blue-Green Deployment..." -ForegroundColor Green

# Install Chocolatey
Write-Host "1. Installing Chocolatey..." -ForegroundColor Yellow
Set-ExecutionPolicy Bypass -Scope Process -Force
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Refresh environment variables
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Install Minikube
Write-Host "2. Installing Minikube..." -ForegroundColor Yellow
choco install minikube -y

# Install kubectl
Write-Host "3. Installing Kubectl..." -ForegroundColor Yellow
choco install kubernetes-cli -y

# Refresh environment variables again
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Start Minikube
Write-Host "4. Starting Minikube..." -ForegroundColor Yellow
minikube start

# Create namespace and apply Kubernetes configs
Write-Host "5. Setting up Kubernetes resources..." -ForegroundColor Yellow
kubectl create namespace timer-app
kubectl apply -f k8s/

# Verify installation
Write-Host "`nVerifying installation..." -ForegroundColor Green
Write-Host "Minikube status:" -ForegroundColor Yellow
minikube status

Write-Host "`nKubernetes resources:" -ForegroundColor Yellow
kubectl get all -n timer-app

Write-Host "`nInstallation complete!" -ForegroundColor Green
Write-Host "Next steps:"
Write-Host "1. Configure Jenkins at http://localhost:8082"
Write-Host "2. Install required Jenkins plugins"
Write-Host "3. Set up Docker Hub and Kubernetes credentials in Jenkins"
Write-Host "4. Create and run the pipeline"