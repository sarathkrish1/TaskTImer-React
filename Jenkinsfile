pipeline {
    agent any

    environment {
        DOCKER_REGISTRY = 'tharunk03'
        IMAGE_NAME = 'timer-app'
        IMAGE_TAG = "${BUILD_NUMBER}"
        KUBECONFIG = credentials('kubeconfig')
        KUBE_NAMESPACE = 'timer-app'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.GIT_COMMIT_SHORT = sh(
                        script: "git rev-parse --short HEAD",
                        returnStdout: true
                    ).trim()
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh """
                        eval \$(minikube docker-env)
                        docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
                        docker build -t ${IMAGE_NAME}:latest .
                    """
                }
            }
        }

        stage('Prepare Manifests') {
            steps {
                script {
                    sh """
                        # Create a backup
                        cp k8s/kustomization.yaml k8s/kustomization.yaml.bak
                        
                        # Replace newTag with quoted version
                        sed -i '' 's/newTag: .*/newTag: "'${IMAGE_TAG}'"/' k8s/kustomization.yaml
                        
                        # Verify the change
                        echo "Updated kustomization.yaml:"
                        grep newTag k8s/kustomization.yaml
                    """
                    sh "kubectl apply -k k8s/"
                }
            }
        }

        stage('Blue-Green Deploy') {
            steps {
                script {
                    def currentColor = sh(
                        script: "kubectl get service timer-app-service -n ${KUBE_NAMESPACE} -o jsonpath='{.spec.selector.track}' 2>/dev/null || true",
                        returnStdout: true
                    ).trim()

                    if (!currentColor) {
                        currentColor = 'blue'
                    }

                    env.ACTIVE_COLOR = currentColor
                    env.TARGET_COLOR = currentColor == 'blue' ? 'green' : 'blue'

                    echo "Active color: ${env.ACTIVE_COLOR} -> Target color: ${env.TARGET_COLOR}"

                    def targetDeployment = "timer-app-${env.TARGET_COLOR}"

                    sh """
                        kubectl set image deployment/${targetDeployment} timer-app=${IMAGE_NAME}:${IMAGE_TAG} -n ${KUBE_NAMESPACE}
                        kubectl rollout status deployment/${targetDeployment} -n ${KUBE_NAMESPACE} --timeout=300s
                        kubectl wait --for=condition=available deployment/${targetDeployment} -n ${KUBE_NAMESPACE} --timeout=300s
                        kubectl wait --for=condition=ready pod -l app=timer-app,track=${env.TARGET_COLOR} -n ${KUBE_NAMESPACE} --timeout=300s
                    """
                }
            }
        }

        stage('Smoke Test New Color') {
            steps {
                script {
                    sh """
                        set -e
                        POD_NAME=\$(kubectl get pods -n ${KUBE_NAMESPACE} -l app=timer-app,track=${env.TARGET_COLOR} -o jsonpath='{.items[0].metadata.name}')
                        echo "Testing pod: \$POD_NAME"
                        
                        # Start port-forward in background
                        kubectl port-forward -n ${KUBE_NAMESPACE} pod/\$POD_NAME 3001:80 >/tmp/timer-app-bluegreen-\${BUILD_NUMBER}.log 2>&1 &
                        PF_PID=\$!
                        echo "Port-forward started with PID: \$PF_PID"
                        
                        # Wait for port-forward to be ready
                        sleep 15
                        
                        # Test the application
                        set +e
                        curl -f http://localhost:3001 --connect-timeout 10 --max-time 30
                        STATUS=\$?
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
                        kubectl patch service timer-app-service -n ${KUBE_NAMESPACE} --type=merge -p '{"spec":{"selector":{"app":"timer-app","track":"${env.TARGET_COLOR}"}}}'
                    """

                    if (env.ACTIVE_COLOR && env.ACTIVE_COLOR != env.TARGET_COLOR) {
                        sh """
                            kubectl scale deployment/timer-app-${env.ACTIVE_COLOR} -n ${KUBE_NAMESPACE} --replicas=1
                        """
                    }
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
                        eval \$(minikube docker-env)
                        docker image prune -f
                    """
                }
            }
        }
    }

    post {
        always {
            script {
                try {
                    cleanWs()
                } catch (Exception e) {
                    echo "Warning: Could not clean workspace: ${e.getMessage()}"
                }
            }
        }

        success {
            script {
                try {
                    echo "✅ Pipeline completed successfully!"
                    if (env.TARGET_COLOR) {
                        echo "🚀 Timer app deployed to ${env.TARGET_COLOR} with image: ${DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
                    } else {
                        echo "🚀 Timer app deployed successfully!"
                    }
                } catch (Exception e) {
                    echo "✅ Pipeline completed successfully!"
                }
            }
        }

        failure {
            script {
                try {
                    echo "❌ Pipeline failed!"
                    if (env.ACTIVE_COLOR && env.ACTIVE_COLOR.trim() && env.TARGET_COLOR && env.TARGET_COLOR.trim()) {
                        sh """
                            kubectl patch service timer-app-service -n ${KUBE_NAMESPACE} --type=merge -p '{"spec":{"selector":{"app":"timer-app","track":"${env.ACTIVE_COLOR}"}}}' || true
                            kubectl rollout undo deployment/timer-app-${env.TARGET_COLOR} -n ${KUBE_NAMESPACE} || true
                        """
                    }
                } catch (Exception e) {
                    echo "❌ Pipeline failed! Error: ${e.getMessage()}"
                }
            }
        }
    }
}
