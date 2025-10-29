#!/bin/bash
# Script to test blue-green deployment locally

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
NAMESPACE="timer-app"
IMAGE_NAME="timer-app"
REGISTRY="${DOCKER_REGISTRY:-localhost:5000}"
BUILD_NUMBER="${BUILD_NUMBER:-test}"

echo -e "${BLUE}Starting Blue-Green Deployment Test${NC}"

# Function to check deployment status
check_deployment() {
    local color=$1
    echo -e "\n${BLUE}Checking $color deployment...${NC}"
    kubectl rollout status deployment/timer-app-$color -n $NAMESPACE --timeout=60s || {
        echo -e "${RED}Deployment $color failed${NC}"
        return 1
    }
}

# Function to get active color
get_active_color() {
    local active_color=$(kubectl get service timer-app-service -n $NAMESPACE -o jsonpath='{.spec.selector.track}')
    echo ${active_color:-blue}
}

# Function to switch traffic
switch_traffic() {
    local target_color=$1
    echo -e "\n${BLUE}Switching traffic to $target_color...${NC}"
    kubectl patch service timer-app-service -n $NAMESPACE --type=merge \
        -p "{\"spec\":{\"selector\":{\"app\":\"timer-app\",\"track\":\"$target_color\"}}}"
}

# Build and tag image
echo -e "\n${BLUE}Building Docker image...${NC}"
docker build -t $REGISTRY/$IMAGE_NAME:$BUILD_NUMBER .
docker tag $REGISTRY/$IMAGE_NAME:$BUILD_NUMBER $REGISTRY/$IMAGE_NAME:latest

# Push image (if registry specified)
if [ "$REGISTRY" != "localhost:5000" ]; then
    echo -e "\n${BLUE}Pushing image to registry...${NC}"
    docker push $REGISTRY/$IMAGE_NAME:$BUILD_NUMBER
    docker push $REGISTRY/$IMAGE_NAME:latest
fi

# Get active color and determine target
ACTIVE_COLOR=$(get_active_color)
TARGET_COLOR=$([ "$ACTIVE_COLOR" == "blue" ] && echo "green" || echo "blue")
echo -e "\n${BLUE}Active color: $ACTIVE_COLOR, Target color: $TARGET_COLOR${NC}"

# Update target deployment
echo -e "\n${BLUE}Updating $TARGET_COLOR deployment...${NC}"
kubectl set image deployment/timer-app-$TARGET_COLOR \
    timer-app=$REGISTRY/$IMAGE_NAME:$BUILD_NUMBER -n $NAMESPACE

# Check deployment status
check_deployment $TARGET_COLOR || {
    echo -e "${RED}Deployment failed, aborting${NC}"
    exit 1
}

# Run smoke test
echo -e "\n${BLUE}Running smoke tests...${NC}"
POD_NAME=$(kubectl get pods -n $NAMESPACE -l app=timer-app,track=$TARGET_COLOR \
    --field-selector=status.phase=Running -o jsonpath='{.items[-1].metadata.name}')

# Test endpoint
echo -e "\n${BLUE}Testing application endpoint...${NC}"
kubectl exec -n $NAMESPACE $POD_NAME -- curl -sf http://localhost:80 > /dev/null
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Smoke test passed${NC}"
    
    # Switch traffic
    switch_traffic $TARGET_COLOR
    echo -e "${GREEN}Successfully switched traffic to $TARGET_COLOR${NC}"
    
    # Optional: delete old deployment
    read -p "Delete old ($ACTIVE_COLOR) deployment? [y/N] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        kubectl delete deployment timer-app-$ACTIVE_COLOR -n $NAMESPACE
        echo -e "${GREEN}Deleted old deployment${NC}"
    fi
else
    echo -e "${RED}Smoke test failed${NC}"
    echo -e "${BLUE}Rolling back...${NC}"
    kubectl rollout undo deployment/timer-app-$TARGET_COLOR -n $NAMESPACE
    exit 1
fi

echo -e "\n${GREEN}Blue-Green deployment test completed successfully!${NC}"
echo -e "To verify: kubectl get all -n $NAMESPACE"