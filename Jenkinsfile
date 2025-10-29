pipeline {
    agent {
        docker {
            image 'codewind/docker-dind'
            args '-v /var/run/docker.sock:/var/run/docker.sock'
        }
    }

    environment {
        NAMESPACE = 'timer-app'
        IMAGE_NAME = 'timer-app'
        REGISTRY = "docker.io/sarathkrishnan"
        IMAGE_TAG = "${BUILD_NUMBER}"
        TARGET_COLOR = 'green'
        ACTIVE_COLOR = 'blue'
        DOCKER_BUILDKIT = '1'
    }

    stages {
        stage('Setup Tools') {
            steps {
                sh '''
                    # Update and install required packages
                    apt-get update
                    apt-get install -y curl wget apt-transport-https gnupg2

                    # Install kubectl
                    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                    chmod +x kubectl
                    mv kubectl /usr/local/bin/

                    # Test tools
                    docker --version
                    kubectl version --client
                '''
            }
        }

        stage('Checkout') {
            steps {
                checkout scm
                sh 'git rev-parse --short HEAD || true'
            }
        }

        stage('Build') {
            steps {
                script {
                    def imageFull = "${env.REGISTRY}/${env.IMAGE_NAME}:${env.IMAGE_TAG}"
                    echo "Building ${imageFull}"
                    
                    // Build with proper error handling
                    sh """
                        docker info
                        docker build --progress=plain -t ${imageFull} -t ${env.REGISTRY}/${env.IMAGE_NAME}:latest .
                    """
                }
            }
        }

        stage('Push') {
            steps {
                script {
                    // Use a Jenkins credential (username/password) with id 'dockerhub-creds' or update the id below
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                        sh "echo \$DOCKER_PASS | docker login ${env.REGISTRY} -u \$DOCKER_USER --password-stdin"
                        sh "docker push ${env.REGISTRY}/${env.IMAGE_NAME}:${env.IMAGE_TAG}"
                        sh "docker push ${env.REGISTRY}/${env.IMAGE_NAME}:latest || true"
                    }
                }
            }
        }

        stage('Determine Target Color') {
            steps {
                script {
                    // Detect active color from service and pick the opposite as target
                    withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG_FILE')]) {
                        withEnv(["KUBECONFIG=${KUBECONFIG_FILE}"]) {
                            def active = sh(script: "kubectl get service timer-app-service -n ${env.NAMESPACE} -o \"jsonpath={.spec.selector.track}\"", returnStdout: true).trim()
                            if (!active) {
                                echo "No active color found, defaulting active=blue"
                                active = 'blue'
                            }
                            env.ACTIVE_COLOR = active
                            env.TARGET_COLOR = (active == 'blue') ? 'green' : 'blue'
                            echo "Active color: ${env.ACTIVE_COLOR}. Deploying to target color: ${env.TARGET_COLOR}"
                        }
                    }
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                script {
                    // Requires a Jenkins 'Secret file' credential containing kubeconfig with id 'kubeconfig'
                    withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG_FILE')]) {
                        withEnv(["KUBECONFIG=${KUBECONFIG_FILE}"]) {
                            def imageFull = "${env.REGISTRY}/${env.IMAGE_NAME}:${env.IMAGE_TAG}"

                            // Update target deployment with new image
                            sh "kubectl set image deployment/timer-app-${env.TARGET_COLOR} timer-app=${imageFull} -n ${env.NAMESPACE}"
                            sh "kubectl rollout status deployment/timer-app-${env.TARGET_COLOR} -n ${env.NAMESPACE} --timeout=300s"

                            // Wait until pods are ready
                            sh "kubectl wait --for=condition=ready pod -l app=timer-app,track=${env.TARGET_COLOR} -n ${env.NAMESPACE} --timeout=300s"
                        }
                    }
                }
            }
        }

        stage('Smoke Test') {
            steps {
                script {
                    withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG_FILE')]) {
                        withEnv(["KUBECONFIG=${KUBECONFIG_FILE}"]) {
                            sh '''#!/bin/bash
                            set -euo pipefail
                            echo "🔍 Running smoke tests against deployment in ${NAMESPACE} (track=${TARGET_COLOR})"

                            # Wait for pods to be ready
                            echo "⏳ Waiting for pods to be ready..."
                            kubectl wait --for=condition=ready pod -l app=timer-app,track=${TARGET_COLOR} -n ${NAMESPACE} --timeout=120s --field-selector=status.phase=Running || {
                                echo "❌ Failed waiting for pods to be ready"
                                exit 1
                            }

                            # Try ingress first (if available)
                            INGRESS_HOST=$(kubectl get ingress -n ${NAMESPACE} timer-app-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
                            if [ -n "$INGRESS_HOST" ]; then
                                echo "🌐 Testing via Ingress at $INGRESS_HOST..."
                                for i in 1 2 3; do
                                    echo "Attempt $i via ingress"
                                    if curl -f -H "Host: timer-app.local" http://$INGRESS_HOST --connect-timeout 10 --max-time 15; then
                                        echo "✅ Smoke test passed via ingress"
                                        exit 0
                                    fi
                                    sleep 5
                                done
                                echo "⚠️ Ingress test failed, falling back to service"
                            fi

                            # Try service via port-forward
                            echo "🔄 Testing via service port-forward..."
                            kubectl port-forward -n ${NAMESPACE} service/timer-app-service 9999:80 &
                            PF_PID=$!
                            sleep 5

                            set +e
                            for i in 1 2 3; do
                                echo "Attempt $i via service"
                                if curl -f http://localhost:9999 --connect-timeout 10 --max-time 15; then
                                    echo "✅ Smoke test passed via service"
                                    kill $PF_PID 2>/dev/null || true
                                    exit 0
                                fi
                                sleep 5
                            done
                            kill $PF_PID 2>/dev/null || true
                            echo "⚠️ Service test failed, falling back to pod exec"

                            # Last resort: test via pod exec
                            echo "🔄 Testing via pod exec..."
                            POD_NAME=$(kubectl get pods -n ${NAMESPACE} -l app=timer-app,track=${TARGET_COLOR} --field-selector=status.phase=Running -o jsonpath='{.items[-1].metadata.name}')
                            echo "Selected pod: ${POD_NAME}"

                            for i in 1 2 3; do
                                echo "Attempt $i via pod exec"
                                if kubectl exec -n ${NAMESPACE} ${POD_NAME} -- curl -f http://localhost:80 --connect-timeout 10 --max-time 15; then
                                    echo "✅ Smoke test passed via pod exec"
                                    exit 0
                                fi
                                sleep 5
                            done

                            echo "❌ All smoke test methods failed"
                            exit 1
                            '''
                        }
                    }
                }
            }
        }

        stage('Switch Traffic') {
            steps {
                script {
                    withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG_FILE')]) {
                        withEnv(["KUBECONFIG=${KUBECONFIG_FILE}"]) {
                            sh "kubectl patch service timer-app-service -n ${env.NAMESPACE} --type=merge -p '{\"spec\":{\"selector\":{\"app\":\"timer-app\",\"track\":\"${env.TARGET_COLOR}\"}}}'"
                            sh "sleep 5"
                            sh "kubectl get service timer-app-service -n ${env.NAMESPACE} -o jsonpath='{.spec.selector.track}'"
                        }
                    }
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
                echo 'Pipeline failed — attempting rollback'
                withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG_FILE')]) {
                    withEnv(["KUBECONFIG=${KUBECONFIG_FILE}"]) {
                        sh "kubectl patch service timer-app-service -n ${env.NAMESPACE} --type=merge -p '{\"spec\":{\"selector\":{\"app\":\"timer-app\",\"track\":\"blue\"}}}' || true"
                        sh "kubectl rollout undo deployment/timer-app-${env.TARGET_COLOR} -n ${env.NAMESPACE} || true"
                    }
                }
            }
        }
        success {
            echo 'Deployment successful'
        }
    }
}