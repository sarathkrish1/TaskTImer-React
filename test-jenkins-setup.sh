#!/bin/bash

# Quick Test Script for Jenkins CI/CD Pipeline
echo "🧪 Testing Jenkins CI/CD Pipeline Setup"
echo "========================================"

# Test 1: Kubernetes Connection
echo "1️⃣ Testing Kubernetes Connection..."
if kubectl --kubeconfig=jenkins-kubeconfig.yaml get nodes >/dev/null 2>&1; then
    echo "   ✅ Kubernetes connection successful"
else
    echo "   ❌ Kubernetes connection failed"
    exit 1
fi

# Test 2: Application Status
echo "2️⃣ Checking Application Status..."
BLUE_PODS=$(kubectl --kubeconfig=jenkins-kubeconfig.yaml get pods -n timer-app -l track=blue --no-headers | wc -l)
GREEN_PODS=$(kubectl --kubeconfig=jenkins-kubeconfig.yaml get pods -n timer-app -l track=green --no-headers | wc -l)
echo "   📊 Blue pods: $BLUE_PODS"
echo "   📊 Green pods: $GREEN_PODS"

if [ $BLUE_PODS -gt 0 ] && [ $GREEN_PODS -gt 0 ]; then
    echo "   ✅ Both blue and green environments running"
else
    echo "   ❌ Missing blue or green environments"
    exit 1
fi

# Test 3: Service Configuration
echo "3️⃣ Checking Service Configuration..."
CURRENT_TRACK=$(kubectl --kubeconfig=jenkins-kubeconfig.yaml get service timer-app-service -n timer-app -o jsonpath='{.spec.selector.track}' 2>/dev/null)
echo "   🎯 Current traffic routing: $CURRENT_TRACK"

if [ -n "$CURRENT_TRACK" ]; then
    echo "   ✅ Service routing configured"
else
    echo "   ❌ Service routing not configured"
    exit 1
fi

# Test 4: HPA Configuration
echo "4️⃣ Checking HPA Configuration..."
BLUE_HPA=$(kubectl --kubeconfig=jenkins-kubeconfig.yaml get hpa timer-app-blue-hpa -n timer-app --no-headers 2>/dev/null | wc -l)
GREEN_HPA=$(kubectl --kubeconfig=jenkins-kubeconfig.yaml get hpa timer-app-green-hpa -n timer-app --no-headers 2>/dev/null | wc -l)

if [ $BLUE_HPA -gt 0 ] && [ $GREEN_HPA -gt 0 ]; then
    echo "   ✅ HPA configured for both environments"
else
    echo "   ❌ HPA not configured properly"
    exit 1
fi

# Test 5: Docker Build
echo "5️⃣ Testing Docker Build..."
if eval $(minikube docker-env) && docker build -t timer-app:test . >/dev/null 2>&1; then
    echo "   ✅ Docker build successful"
else
    echo "   ❌ Docker build failed"
    exit 1
fi

# Test 6: Blue-Green Switch Test
echo "6️⃣ Testing Blue-Green Switch..."
ORIGINAL_TRACK=$CURRENT_TRACK
TARGET_TRACK=$([ "$CURRENT_TRACK" = "blue" ] && echo "green" || echo "blue")

echo "   🔄 Switching from $ORIGINAL_TRACK to $TARGET_TRACK..."
kubectl --kubeconfig=jenkins-kubeconfig.yaml patch service timer-app-service -n timer-app --type=merge -p "{\"spec\":{\"selector\":{\"app\":\"timer-app\",\"track\":\"$TARGET_TRACK\"}}}" >/dev/null 2>&1

sleep 5

NEW_TRACK=$(kubectl --kubeconfig=jenkins-kubeconfig.yaml get service timer-app-service -n timer-app -o jsonpath='{.spec.selector.track}' 2>/dev/null)
if [ "$NEW_TRACK" = "$TARGET_TRACK" ]; then
    echo "   ✅ Traffic switch successful: $ORIGINAL_TRACK → $TARGET_TRACK"
else
    echo "   ❌ Traffic switch failed"
    exit 1
fi

# Switch back to original
kubectl --kubeconfig=jenkins-kubeconfig.yaml patch service timer-app-service -n timer-app --type=merge -p "{\"spec\":{\"selector\":{\"app\":\"timer-app\",\"track\":\"$ORIGINAL_TRACK\"}}}" >/dev/null 2>&1
echo "   🔄 Switched back to $ORIGINAL_TRACK"

# Test 7: Application Health
echo "7️⃣ Testing Application Health..."
kubectl --kubeconfig=jenkins-kubeconfig.yaml port-forward -n timer-app service/timer-app-service 8080:80 >/dev/null 2>&1 &
PF_PID=$!
sleep 5

if curl -f http://localhost:8080 >/dev/null 2>&1; then
    echo "   ✅ Application responding with HTTP 200"
else
    echo "   ❌ Application health check failed"
    kill $PF_PID 2>/dev/null || true
    exit 1
fi

kill $PF_PID 2>/dev/null || true

echo ""
echo "🎉 ALL TESTS PASSED!"
echo "==================="
echo "✅ Kubernetes cluster connected"
echo "✅ Blue-Green environments running"
echo "✅ Service routing configured"
echo "✅ HPA configured"
echo "✅ Docker build working"
echo "✅ Traffic switching working"
echo "✅ Application healthy"
echo ""
echo "🚀 Ready for Jenkins Pipeline!"
echo "📋 Upload jenkins-kubeconfig.yaml to Jenkins credentials"
echo "🎯 Configure pipeline with Jenkinsfile"
echo "👨‍🏫 Ready for Professor Demonstration!"
