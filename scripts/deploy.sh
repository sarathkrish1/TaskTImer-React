#!/bin/bash

# Jenkins CI/CD Pipeline Helper Scripts

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
DOCKER_REGISTRY=${DOCKER_REGISTRY:-"your-registry.com"}
IMAGE_NAME=${IMAGE_NAME:-"timer-app"}
NAMESPACE=${NAMESPACE:-"timer-app"}
BUILD_NUMBER=${BUILD_NUMBER:-"latest"}

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Build Docker image
build_image() {
    log_info "Building Docker image..."
    docker build -t "${DOCKER_REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER}" .
    docker build -t "${DOCKER_REGISTRY}/${IMAGE_NAME}:latest" .
    log_info "Docker image built successfully"
}

# Push Docker image
push_image() {
    log_info "Pushing Docker image to registry..."
    docker push "${DOCKER_REGISTRY}/${IMAGE_NAME}:${BUILD_NUMBER}"
    docker push "${DOCKER_REGISTRY}/${IMAGE_NAME}:latest"
    log_info "Docker image pushed successfully"
}

# Deploy to Kubernetes
deploy_k8s() {
    log_info "Deploying to Kubernetes..."
    
    # Update image tag in kustomization.yaml
    sed -i "s/newTag: .*/newTag: ${BUILD_NUMBER}/" k8s/kustomization.yaml
    
    # Apply Kubernetes manifests
    kubectl apply -k k8s/
    
    # Wait for deployment
    kubectl rollout status deployment/timer-app-deployment -n ${NAMESPACE} --timeout=300s
    
    log_info "Deployment completed successfully"
}

# Health check
health_check() {
    log_info "Performing health check..."
    
    # Wait for pods to be ready
    kubectl wait --for=condition=ready pod -l app=timer-app -n ${NAMESPACE} --timeout=300s
    
    # Test application
    kubectl port-forward -n ${NAMESPACE} service/timer-app-service 8080:80 &
    PF_PID=$!
    
    sleep 10
    
    if curl -f http://localhost:8080 > /dev/null 2>&1; then
        log_info "Health check passed"
    else
        log_error "Health check failed"
        kill $PF_PID 2>/dev/null || true
        exit 1
    fi
    
    kill $PF_PID 2>/dev/null || true
}

# Rollback deployment
rollback() {
    log_warn "Rolling back deployment..."
    kubectl rollout undo deployment/timer-app-deployment -n ${NAMESPACE}
    kubectl rollout status deployment/timer-app-deployment -n ${NAMESPACE} --timeout=300s
    log_info "Rollback completed"
}

# Cleanup old images
cleanup() {
    log_info "Cleaning up old images..."
    docker image prune -f
    log_info "Cleanup completed"
}

# Show deployment status
status() {
    log_info "Deployment Status:"
    echo "=================="
    kubectl get all -n ${NAMESPACE}
    echo ""
    kubectl get hpa -n ${NAMESPACE}
}

# Main execution
case "${1:-deploy}" in
    "build")
        build_image
        ;;
    "push")
        push_image
        ;;
    "deploy")
        deploy_k8s
        ;;
    "health")
        health_check
        ;;
    "rollback")
        rollback
        ;;
    "cleanup")
        cleanup
        ;;
    "status")
        status
        ;;
    "full")
        build_image
        push_image
        deploy_k8s
        health_check
        ;;
    *)
        echo "Usage: $0 {build|push|deploy|health|rollback|cleanup|status|full}"
        echo ""
        echo "Commands:"
        echo "  build     - Build Docker image"
        echo "  push      - Push Docker image to registry"
        echo "  deploy    - Deploy to Kubernetes"
        echo "  health    - Perform health check"
        echo "  rollback  - Rollback deployment"
        echo "  cleanup   - Cleanup old images"
        echo "  status    - Show deployment status"
        echo "  full      - Run complete pipeline"
        exit 1
        ;;
esac
