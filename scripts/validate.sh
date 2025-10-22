#!/bin/bash

# Kubernetes Deployment Validation Script

set -e

NAMESPACE=${NAMESPACE:-"timer-app"}
TIMEOUT=${TIMEOUT:-300}

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if namespace exists
check_namespace() {
    log_info "Checking namespace..."
    if kubectl get namespace ${NAMESPACE} > /dev/null 2>&1; then
        log_info "Namespace ${NAMESPACE} exists"
    else
        log_error "Namespace ${NAMESPACE} does not exist"
        exit 1
    fi
}

# Check deployment status
check_deployment() {
    log_info "Checking deployment status..."
    
    # Get deployment status
    READY=$(kubectl get deployment timer-app-deployment -n ${NAMESPACE} -o jsonpath='{.status.readyReplicas}')
    DESIRED=$(kubectl get deployment timer-app-deployment -n ${NAMESPACE} -o jsonpath='{.spec.replicas}')
    
    if [ "${READY}" = "${DESIRED}" ]; then
        log_info "Deployment is ready (${READY}/${DESIRED})"
    else
        log_error "Deployment not ready (${READY}/${DESIRED})"
        exit 1
    fi
}

# Check pod status
check_pods() {
    log_info "Checking pod status..."
    
    # Wait for pods to be ready
    kubectl wait --for=condition=ready pod -l app=timer-app -n ${NAMESPACE} --timeout=${TIMEOUT}s
    
    # Check pod count
    POD_COUNT=$(kubectl get pods -n ${NAMESPACE} -l app=timer-app --no-headers | wc -l)
    READY_PODS=$(kubectl get pods -n ${NAMESPACE} -l app=timer-app --no-headers | grep "Running" | wc -l)
    
    log_info "Pods status: ${READY_PODS}/${POD_COUNT} running"
    
    if [ "${READY_PODS}" != "${POD_COUNT}" ]; then
        log_error "Not all pods are running"
        kubectl get pods -n ${NAMESPACE} -l app=timer-app
        exit 1
    fi
}

# Check service
check_service() {
    log_info "Checking service..."
    
    if kubectl get service timer-app-service -n ${NAMESPACE} > /dev/null 2>&1; then
        log_info "Service exists"
        
        # Check endpoints
        ENDPOINTS=$(kubectl get endpoints timer-app-service -n ${NAMESPACE} -o jsonpath='{.subsets[0].addresses[*].ip}' | wc -w)
        log_info "Service has ${ENDPOINTS} endpoints"
    else
        log_error "Service does not exist"
        exit 1
    fi
}

# Check ingress
check_ingress() {
    log_info "Checking ingress..."
    
    if kubectl get ingress timer-app-ingress -n ${NAMESPACE} > /dev/null 2>&1; then
        log_info "Ingress exists"
    else
        log_warn "Ingress does not exist (optional)"
    fi
}

# Check HPA
check_hpa() {
    log_info "Checking HPA..."
    
    if kubectl get hpa timer-app-hpa -n ${NAMESPACE} > /dev/null 2>&1; then
        log_info "HPA exists"
        
        # Get HPA status
        CURRENT=$(kubectl get hpa timer-app-hpa -n ${NAMESPACE} -o jsonpath='{.status.currentReplicas}')
        DESIRED=$(kubectl get hpa timer-app-hpa -n ${NAMESPACE} -o jsonpath='{.status.desiredReplicas}')
        log_info "HPA status: ${CURRENT}/${DESIRED} replicas"
    else
        log_warn "HPA does not exist (optional)"
    fi
}

# Test application connectivity
test_connectivity() {
    log_info "Testing application connectivity..."
    
    # Port forward
    kubectl port-forward -n ${NAMESPACE} service/timer-app-service 8080:80 &
    PF_PID=$!
    
    # Wait for port forward
    sleep 5
    
    # Test HTTP response
    if curl -f http://localhost:8080 > /dev/null 2>&1; then
        log_info "Application is responding"
    else
        log_error "Application is not responding"
        kill $PF_PID 2>/dev/null || true
        exit 1
    fi
    
    # Cleanup
    kill $PF_PID 2>/dev/null || true
}

# Show overall status
show_status() {
    log_info "Overall deployment status:"
    echo "=============================="
    kubectl get all -n ${NAMESPACE}
    echo ""
    kubectl get hpa -n ${NAMESPACE} 2>/dev/null || true
    echo ""
    kubectl get ingress -n ${NAMESPACE} 2>/dev/null || true
}

# Main execution
main() {
    log_info "Starting deployment validation..."
    
    check_namespace
    check_deployment
    check_pods
    check_service
    check_ingress
    check_hpa
    test_connectivity
    show_status
    
    log_info "✅ All checks passed! Deployment is healthy."
}

# Run main function
main "$@"
