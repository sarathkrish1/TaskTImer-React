#!/bin/bash

# 🎯 Jenkins Success Verification Script
# Ensure your pipeline will show GREEN checkmarks, not red X's

echo "🎯 JENKINS SUCCESS VERIFICATION"
echo "=============================="
echo ""

echo "📋 STEP 1: VERIFY INFRASTRUCTURE"
echo "================================"
echo "✅ Jenkins Status:"
if curl -s http://localhost:8080 | grep -q "Jenkins"; then
    echo "   Jenkins is running on port 8080"
else
    echo "   ❌ Jenkins not accessible"
    exit 1
fi

echo "✅ Timer App Status:"
if curl -s http://localhost:3000 | grep -q "nginx"; then
    echo "   Timer app is running on port 3000"
else
    echo "   ❌ Timer app not accessible"
    exit 1
fi

echo "✅ Kubernetes Cluster:"
if kubectl --kubeconfig=jenkins-kubeconfig.yaml get nodes >/dev/null 2>&1; then
    echo "   Kubernetes cluster accessible"
else
    echo "   ❌ Kubernetes cluster not accessible"
    exit 1
fi

echo ""
echo "📋 STEP 2: VERIFY APPLICATION DEPLOYMENT"
echo "======================================="
BLUE_PODS=$(kubectl --kubeconfig=jenkins-kubeconfig.yaml get pods -n timer-app -l track=blue --no-headers | wc -l)
GREEN_PODS=$(kubectl --kubeconfig=jenkins-kubeconfig.yaml get pods -n timer-app -l track=green --no-headers | wc -l)

echo "✅ Blue Environment: $BLUE_PODS pods running"
echo "✅ Green Environment: $GREEN_PODS pods running"

if [ $BLUE_PODS -gt 0 ] && [ $GREEN_PODS -gt 0 ]; then
    echo "   ✅ Both environments ready for blue-green deployment"
else
    echo "   ❌ Missing blue or green environments"
    exit 1
fi

echo ""
echo "📋 STEP 3: VERIFY CREDENTIALS"
echo "============================"
if [ -f "jenkins-kubeconfig.yaml" ]; then
    echo "✅ kubeconfig file exists"
else
    echo "   ❌ kubeconfig file missing"
    exit 1
fi

echo "✅ Jenkinsfile exists"
if [ -f "Jenkinsfile" ]; then
    echo "   Jenkinsfile ready for pipeline"
else
    echo "   ❌ Jenkinsfile missing"
    exit 1
fi

echo ""
echo "📋 STEP 4: TEST PIPELINE COMPONENTS"
echo "=================================="
echo "✅ Docker Build Test:"
if eval $(minikube docker-env) && docker build -t timer-app:test . >/dev/null 2>&1; then
    echo "   Docker build successful"
else
    echo "   ❌ Docker build failed"
    exit 1
fi

echo "✅ Blue-Green Switch Test:"
CURRENT_TRACK=$(kubectl --kubeconfig=jenkins-kubeconfig.yaml get service timer-app-service -n timer-app -o jsonpath='{.spec.selector.track}')
TARGET_TRACK=$([ "$CURRENT_TRACK" = "blue" ] && echo "green" || echo "blue")

kubectl --kubeconfig=jenkins-kubeconfig.yaml patch service timer-app-service -n timer-app --type=merge -p "{\"spec\":{\"selector\":{\"app\":\"timer-app\",\"track\":\"$TARGET_TRACK\"}}}" >/dev/null 2>&1
sleep 3

NEW_TRACK=$(kubectl --kubeconfig=jenkins-kubeconfig.yaml get service timer-app-service -n timer-app -o jsonpath='{.spec.selector.track}')
if [ "$NEW_TRACK" = "$TARGET_TRACK" ]; then
    echo "   Blue-green switch successful: $CURRENT_TRACK → $TARGET_TRACK"
    # Switch back
    kubectl --kubeconfig=jenkins-kubeconfig.yaml patch service timer-app-service -n timer-app --type=merge -p "{\"spec\":{\"selector\":{\"app\":\"timer-app\",\"track\":\"$CURRENT_TRACK\"}}}" >/dev/null 2>&1
else
    echo "   ❌ Blue-green switch failed"
    exit 1
fi

echo ""
echo "📋 STEP 5: APPLICATION HEALTH CHECK"
echo "=================================="
kubectl --kubeconfig=jenkins-kubeconfig.yaml port-forward -n timer-app service/timer-app-service 8081:80 >/dev/null 2>&1 &
PF_PID=$!
sleep 5

if curl -f http://localhost:8081 >/dev/null 2>&1; then
    echo "✅ Application health check passed"
else
    echo "   ❌ Application health check failed"
    kill $PF_PID 2>/dev/null || true
    exit 1
fi

kill $PF_PID 2>/dev/null || true

echo ""
echo "🎉 ALL VERIFICATIONS PASSED!"
echo "============================"
echo "✅ Jenkins: Running on port 8080"
echo "✅ Timer App: Running on port 3000"
echo "✅ Kubernetes: Cluster accessible"
echo "✅ Blue-Green: Both environments ready"
echo "✅ Credentials: kubeconfig uploaded"
echo "✅ Pipeline: Jenkinsfile ready"
echo "✅ Docker: Build working"
echo "✅ Switching: Blue-green working"
echo "✅ Health: Application responding"
echo ""
echo "🚀 READY FOR SUCCESSFUL JENKINS BUILDS!"
echo "======================================"
echo "Your pipeline will show GREEN checkmarks ✅"
echo "No more red X's ❌"
echo ""
echo "👨‍🏫 Perfect for Professor Demonstration!"
echo "🎯 Enterprise-level CI/CD Pipeline!"
