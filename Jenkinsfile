pipeline {
    agent any
    
    environment {
        KUBE_NAMESPACE = 'timer-app'
        IMAGE_TAG = "${BUILD_NUMBER}"
        TARGET_COLOR = 'green'
        ACTIVE_COLOR = 'blue'
    }
    
    stages {
        stage('Checkout') {
            steps {
                script {
                    sh 'git rev-parse --short HEAD'
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    sh """
                        eval \$(minikube docker-env)
                        docker build -t timer-app:${IMAGE_TAG} .
                        docker build -t timer-app:latest .
                    """
                }
            }
        }
        
        stage('Prepare Manifests') {
            steps {
                script {
                    sh """
                        cp k8s/kustomization.yaml k8s/kustomization.yaml.bak
                        sed -i '' 's/newTag: .*/newTag: "${IMAGE_TAG}"/' k8s/kustomization.yaml
                        echo 'Updated kustomization.yaml:'
                        grep newTag k8s/kustomization.yaml
                    """
                    sh 'kubectl apply -k k8s/'
                }
            }
        }
        
        stage('Blue-Green Deploy') {
            steps {
                script {
                    def activeColor = sh(
                        script: "kubectl get service timer-app-service -n ${KUBE_NAMESPACE} -o 'jsonpath={.spec.selector.track}'",
                        returnStdout: true
                    ).trim()
                    
                    echo "Active color: ${activeColor} -> Target color: ${TARGET_COLOR}"
                    
                    sh """
                        kubectl set image deployment/timer-app-${TARGET_COLOR} timer-app=timer-app:${IMAGE_TAG} -n ${KUBE_NAMESPACE}
                        kubectl rollout status deployment/timer-app-${TARGET_COLOR} -n ${KUBE_NAMESPACE} --timeout=300s
                        kubectl wait --for=condition=available deployment/timer-app-${TARGET_COLOR} -n ${KUBE_NAMESPACE} --timeout=300s
                        kubectl wait --for=condition=ready pod -l app=timer-app,track=${TARGET_COLOR} -n ${KUBE_NAMESPACE} --timeout=300s
                    """
                }
            }
        }
        
        stage('Smoke Test New Color') {
            steps {
                script {
                    sh """
                        set -e
                        
                        # Wait for pods to be ready and get a running pod
                        echo "Waiting for ${env.TARGET_COLOR} pods to be ready..."
                        kubectl wait --for=condition=ready pod -l app=timer-app,track=${env.TARGET_COLOR} -n ${KUBE_NAMESPACE} --timeout=120s
                        
                        # Get the newest running pod
                        POD_NAME=\$(kubectl get pods -n ${KUBE_NAMESPACE} -l app=timer-app,track=${env.TARGET_COLOR} --field-selector=status.phase=Running -o jsonpath='{.items[-1].metadata.name}')
                        echo "Testing pod: \$POD_NAME"
                        
                        # Verify pod is actually running and ready
                        kubectl get pod \$POD_NAME -n ${KUBE_NAMESPACE}
                        
                        # Wait additional time for pod to be fully ready to serve requests
                        echo "Waiting for pod to be fully ready to serve requests..."
                        sleep 30
                        
                        # Start port-forward in background
                        kubectl port-forward -n ${KUBE_NAMESPACE} pod/\$POD_NAME 3001:80 >/tmp/timer-app-bluegreen-\${BUILD_NUMBER}.log 2>&1 &
                        PF_PID=\$!
                        echo "Port-forward started with PID: \$PF_PID"
                        
                        # Wait for port-forward to be ready
                        sleep 20
                        
                        # Test the application with retries
                        echo "Testing application with retries..."
                        set +e
                        for i in {1..3}; do
                            echo "Attempt \$i/3..."
                            curl -f http://localhost:3001 --connect-timeout 15 --max-time 30
                            STATUS=\$?
                            if [ \$STATUS -eq 0 ]; then
                                echo "Test successful on attempt \$i"
                                break
                            else
                                echo "Test failed on attempt \$i with status: \$STATUS"
                                if [ \$i -lt 3 ]; then
                                    echo "Retrying in 10 seconds..."
                                    sleep 10
                                fi
                            fi
                        done
                        set -e
                        
                        # Clean up port-forward
                        kill \$PF_PID 2>/dev/null || true
                        wait \$PF_PID 2>/dev/null || true
                        
                        echo "Smoke test status: \$STATUS"
                        if [ \$STATUS -ne 0 ]; then
                            echo "Smoke test failed with status: \$STATUS"
                            exit \$STATUS
                        fi
                        echo "Smoke test passed!"
                    """
                }
            }
        }
        
        stage('Switch Traffic') {
            steps {
                script {
                    sh """
                        kubectl patch service timer-app-service -n ${KUBE_NAMESPACE} --type=merge -p '{"spec":{"selector":{"app":"timer-app","track":"${TARGET_COLOR}"}}}'
                        echo "Traffic switched to ${TARGET_COLOR}"
                        
                        # Wait for service to update
                        sleep 10
                        
                        # Verify traffic switch
                        kubectl get service timer-app-service -n ${KUBE_NAMESPACE} -o jsonpath='{.spec.selector.track}'
                    """
                }
            }
        }
        
        stage('Post-Deployment Health Check') {
            steps {
                script {
                    sh """
                        set -e
                        echo "Starting post-deployment health check..."
                        
                        # Start port-forward in background
                        kubectl port-forward -n ${KUBE_NAMESPACE} service/timer-app-service 3000:80 >/tmp/timer-app-service-\${BUILD_NUMBER}.log 2>&1 &
                        PF_PID=\$!
                        echo "Service port-forward started with PID: \$PF_PID"
                        
                        # Wait for port-forward to be ready
                        sleep 15
                        
                        # Test the application
                        set +e
                        curl -f http://localhost:3000 --connect-timeout 10 --max-time 30
                        STATUS=\$?
                        set -e
                        
                        # Clean up port-forward
                        kill \$PF_PID 2>/dev/null || true
                        wait \$PF_PID 2>/dev/null || true
                        
                        echo "Health check status: \$STATUS"
                        if [ \$STATUS -ne 0 ]; then
                            echo "Health check failed with status: \$STATUS"
                            exit \$STATUS
                        fi
                        echo "Health check passed!"
                    """
                }
            }
        }
        
        stage('Housekeeping') {
            steps {
                script {
                    sh """
                        # Clean up old deployments
                        kubectl delete deployment timer-app-${ACTIVE_COLOR} -n ${KUBE_NAMESPACE} --ignore-not-found=true
                        kubectl delete hpa timer-app-${ACTIVE_COLOR}-hpa -n ${KUBE_NAMESPACE} --ignore-not-found=true
                        
                        # Clean up old images
                        docker image prune -f
                        
                        echo "Housekeeping completed"
                    """
                }
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
        failure {
            script {
                echo "❌ Pipeline failed!"
                sh """
                    # Rollback to blue
                    kubectl patch service timer-app-service -n ${KUBE_NAMESPACE} --type=merge -p '{"spec":{"selector":{"app":"timer-app","track":"blue"}}}'
                    kubectl rollout undo deployment/timer-app-${TARGET_COLOR} -n ${KUBE_NAMESPACE}
                """
            }
        }
        success {
            script {
                echo "✅ Pipeline completed successfully!"
                echo "🚀 Timer app deployed successfully!"
            }
        }
    }
}