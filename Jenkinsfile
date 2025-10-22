pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = 'tharunk03'  // Your Docker Hub username
        IMAGE_NAME = 'timer-app'
        IMAGE_TAG = "${BUILD_NUMBER}"
        KUBECONFIG = credentials('kubeconfig')
        DOCKER_CREDENTIALS = credentials('docker-registry-credentials')
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
                    // Build image for minikube Docker registry
                    sh """
                        eval \$(minikube docker-env)
                        docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
                        docker build -t ${IMAGE_NAME}:latest .
                    """
                }
            }
        }
        
        stage('Push Docker Image') {
            steps {
                script {
                    // Skip Docker Hub push for local development
                    echo "Using local Docker images for minikube deployment"
                }
            }
        }
        
        stage('Deploy to Kubernetes') {
            steps {
                script {
                    // Update image tag in kustomization.yaml
                    sh """
                        sed -i '' 's/newTag: .*/newTag: ${IMAGE_TAG}/' k8s/kustomization.yaml
                    """
                    
                    // Deploy to Kubernetes
                    sh """
                        kubectl apply -k k8s/
                    """
                    
                    // Wait for deployment to be ready
                    sh """
                        kubectl rollout status deployment/timer-app-deployment -n ${KUBE_NAMESPACE} --timeout=300s
                    """
                }
            }
        }
        
        stage('Health Check') {
            steps {
                script {
                    // Wait for pods to be ready
                    sh """
                        kubectl wait --for=condition=ready pod -l app=timer-app -n ${KUBE_NAMESPACE} --timeout=300s
                    """
                    
                    // Port forward and test
                    sh """
                        timeout 30 kubectl port-forward -n ${KUBE_NAMESPACE} service/timer-app-service 3000:80 &
                        sleep 10
                        curl -f http://localhost:3000 || exit 1
                        pkill -f "kubectl port-forward"
                    """
                }
            }
        }
        
        stage('Cleanup Old Images') {
            steps {
                script {
                    // Keep only last 5 images
                    sh """
                        docker image prune -f
                        kubectl get images -n ${KUBE_NAMESPACE} --sort-by=.metadata.creationTimestamp | tail -n +6 | awk '{print \$1}' | xargs -r kubectl delete image -n ${KUBE_NAMESPACE}
                    """
                }
            }
        }
    }
    
    post {
        always {
            // Clean up workspace
            cleanWs()
        }
        
        success {
            echo "✅ Pipeline completed successfully!"
            echo "🚀 Timer app deployed with image: ${DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
            
            // Send success notification
            script {
                def message = """
                ✅ Timer App Deployment Successful!
                
                📦 Image: ${DOCKER_REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
                🔗 Commit: ${env.GIT_COMMIT_SHORT}
                🏗️ Build: ${env.BUILD_NUMBER}
                ⏰ Time: ${new Date()}
                
                🌐 Access: kubectl port-forward -n timer-app service/timer-app-service 8080:80
                """
                // Add your notification logic here (Slack, email, etc.)
            }
        }
        
        failure {
            echo "❌ Pipeline failed!"
            
            // Send failure notification
            script {
                def message = """
                ❌ Timer App Deployment Failed!
                
                🔗 Commit: ${env.GIT_COMMIT_SHORT}
                🏗️ Build: ${env.BUILD_NUMBER}
                ⏰ Time: ${new Date()}
                
                📋 Check Jenkins logs for details.
                """
                // Add your notification logic here
            }
            
            // Rollback deployment
            sh """
                kubectl rollout undo deployment/timer-app-deployment -n ${KUBE_NAMESPACE}
            """
        }
    }
}