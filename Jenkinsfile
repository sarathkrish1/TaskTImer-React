pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = 'docker.io'
        IMAGE_NAME = 'timer-app'
        NAMESPACE = 'timer-app'
        KUBECONFIG = credentials('kubeconfig')
    }
    
    stages {
        stage('Checkout') {
            steps {
                script {
                    echo '=== Checking out code from GitHub ==='
                    checkout scm
                    env.GIT_COMMIT_SHORT = sh(
                        script: "git rev-parse --short HEAD",
                        returnStdout: true
                    ).trim()
                    echo "Build Tag: ${env.GIT_COMMIT_SHORT}"
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    echo '=== Building Docker Image ==='
                    withCredentials([usernamePassword(
                        credentialsId: 'docker-hub-credentials',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        sh """
                            echo === DOCKER VERSION ===
                            docker version
                            
                            echo === BUILDING IMAGE ===
                            docker build -t ${DOCKER_USER}/${IMAGE_NAME}:${BUILD_NUMBER} .
                            docker build -t ${DOCKER_USER}/${IMAGE_NAME}:latest .
                            docker build -t ${DOCKER_USER}/${IMAGE_NAME}:${GIT_COMMIT_SHORT} .
                            
                            echo === IMAGE BUILT SUCCESSFULLY ===
                            docker images | grep ${IMAGE_NAME}
                        """
                    }
                }
            }
        }
        
        stage('Test Docker Image') {
            steps {
                script {
                    echo '=== Testing Docker Image ==='
                    withCredentials([usernamePassword(
                        credentialsId: 'docker-hub-credentials',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        sh """
                            echo === RUNNING CONTAINER TEST ===
                            docker run -d --name test-container -p 3001:80 ${DOCKER_USER}/${IMAGE_NAME}:${BUILD_NUMBER}
                            sleep 5
                            
                            echo === HEALTH CHECK ===
                            curl -f http://localhost:3001 || exit 1
                            
                            echo === STOPPING TEST CONTAINER ===
                            docker stop test-container
                            docker rm test-container
                        """
                    }
                }
            }
        }
        
        stage('Push to Docker Hub') {
            steps {
                script {
                    echo '=== Pushing Image to Docker Hub ==='
                    withCredentials([usernamePassword(
                        credentialsId: 'docker-hub-credentials',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        sh """
                            echo === LOGGING IN TO DOCKER HUB ===
                            echo \$DOCKER_PASS | docker login -u \$DOCKER_USER --password-stdin
                            
                            echo === PUSHING IMAGES ===
                            docker push ${DOCKER_USER}/${IMAGE_NAME}:${BUILD_NUMBER}
                            docker push ${DOCKER_USER}/${IMAGE_NAME}:latest
                            docker push ${DOCKER_USER}/${IMAGE_NAME}:${GIT_COMMIT_SHORT}
                            
                            echo === PUSH COMPLETE ===
                        """
                    }
                }
            }
        }
        
        stage('Prepare Kubernetes Manifests') {
            steps {
                script {
                    echo '=== Preparing Kubernetes Manifests ==='
                    withCredentials([usernamePassword(
                        credentialsId: 'docker-hub-credentials',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        sh """
                            echo === UPDATING KUSTOMIZATION ===
                            cd k8s
                            cat > kustomization.yaml <<EOF
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
namespace: ${NAMESPACE}
resources:
  - namespace.yaml
  - configmap.yaml
  - deployment-blue.yaml
  - deployment-green.yaml
  - service.yaml
  - ingress.yaml
  - hpa-blue.yaml
  - hpa-green.yaml
images:
  - name: ${DOCKER_USER}/${IMAGE_NAME}
    newTag: "${BUILD_NUMBER}"
EOF
                            cat kustomization.yaml
                            
                            echo === CREATING NAMESPACE IF NOT EXISTS ===
                            kubectl get namespace ${NAMESPACE} || kubectl create namespace ${NAMESPACE}
                        """
                    }
                }
            }
        }
        
        stage('Blue-Green Deployment') {
            steps {
                script {
                    echo '=== Executing Blue-Green Deployment ==='
                    withCredentials([usernamePassword(
                        credentialsId: 'docker-hub-credentials',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )]) {
                        sh """
                            echo === DETECTING CURRENT LIVE COLOR ===
                            CURRENT_COLOR=\$(kubectl get service timer-app-service -n ${NAMESPACE} -o jsonpath='{.spec.selector.track}' 2>/dev/null || echo "blue")
                            
                            if [ "\$CURRENT_COLOR" = "blue" ]; then
                                NEW_COLOR="green"
                            else
                                NEW_COLOR="blue"
                            fi
                            
                            echo "Current live color: \$CURRENT_COLOR"
                            echo "Deploying to: \$NEW_COLOR"
                            
                            echo === APPLYING MANIFESTS ===
                            kubectl apply -k k8s/
                            
                            echo === UPDATING \$NEW_COLOR DEPLOYMENT ===
                            kubectl set image deployment/timer-app-\${NEW_COLOR} \
                                timer-app=${DOCKER_USER}/${IMAGE_NAME}:${BUILD_NUMBER} \
                                -n ${NAMESPACE}
                            
                            echo === WAITING FOR \$NEW_COLOR PODS TO BE READY ===
                            kubectl rollout status deployment/timer-app-\${NEW_COLOR} -n ${NAMESPACE} --timeout=300s
                            
                            echo === DEPLOYMENT SUCCESSFUL ===
                        """
                    }
                }
            }
        }
        
        stage('Smoke Test New Color') {
            steps {
                script {
                    echo '=== Running Smoke Tests on New Deployment ==='
                    sh """
                        CURRENT_COLOR=\$(kubectl get service timer-app-service -n ${NAMESPACE} -o jsonpath='{.spec.selector.track}' 2>/dev/null || echo "blue")
                        
                        if [ "\$CURRENT_COLOR" = "blue" ]; then
                            NEW_COLOR="green"
                        else
                            NEW_COLOR="blue"
                        fi
                        
                        echo === TESTING \$NEW_COLOR DEPLOYMENT ===
                        POD_NAME=\$(kubectl get pods -n ${NAMESPACE} -l track=\${NEW_COLOR} -o jsonpath='{.items[0].metadata.name}')
                        echo "Testing pod: \$POD_NAME"
                        
                        kubectl port-forward -n ${NAMESPACE} \$POD_NAME 8081:80 &
                        PF_PID=\$!
                        sleep 3
                        
                        echo === HEALTH CHECK ===
                        curl -f http://localhost:8081 || (kill \$PF_PID; exit 1)
                        
                        kill \$PF_PID
                        echo === SMOKE TEST PASSED ===
                    """
                }
            }
        }
        
        stage('Switch Traffic') {
            steps {
                script {
                    echo '=== Switching Traffic to New Deployment ==='
                    sh """
                        CURRENT_COLOR=\$(kubectl get service timer-app-service -n ${NAMESPACE} -o jsonpath='{.spec.selector.track}' 2>/dev/null || echo "blue")
                        
                        if [ "\$CURRENT_COLOR" = "blue" ]; then
                            NEW_COLOR="green"
                            OLD_COLOR="blue"
                        else
                            NEW_COLOR="blue"
                            OLD_COLOR="green"
                        fi
                        
                        echo "Switching from \$OLD_COLOR to \$NEW_COLOR"
                        
                        echo === UPDATING SERVICE SELECTOR ===
                        kubectl patch service timer-app-service -n ${NAMESPACE} \
                            --type=merge -p '{"spec":{"selector":{"track":"'\${NEW_COLOR}'"}}}'
                        
                        echo === SCALING DOWN OLD DEPLOYMENT ===
                        kubectl scale deployment/timer-app-\${OLD_COLOR} --replicas=1 -n ${NAMESPACE}
                        
                        echo === TRAFFIC SWITCHED TO \$NEW_COLOR ===
                    """
                }
            }
        }
        
        stage('Post-Deployment Health Check') {
            steps {
                script {
                    echo '=== Final Health Check ==='
                    sh """
                        echo === CHECKING SERVICE ENDPOINTS ===
                        kubectl get endpoints timer-app-service -n ${NAMESPACE}
                        
                        echo === PORT-FORWARD TEST ===
                        kubectl port-forward -n ${NAMESPACE} service/timer-app-service 8082:80 &
                        PF_PID=\$!
                        sleep 5
                        
                        curl -f http://localhost:8082 || (kill \$PF_PID; exit 1)
                        
                        kill \$PF_PID
                        echo === DEPLOYMENT VERIFIED ===
                    """
                }
            }
        }
        
        stage('Cleanup') {
            steps {
                script {
                    echo '=== Cleaning Up ==='
                    sh """
                        echo === PRUNING DOCKER IMAGES ===
                        docker image prune -f
                        
                        echo === CLEANUP COMPLETE ===
                    """
                }
            }
        }
    }
    
    post {
        success {
            echo '=== PIPELINE COMPLETED SUCCESSFULLY ==='
            echo "Deployed ${IMAGE_NAME}:${BUILD_NUMBER} to ${NAMESPACE} namespace"
        }
        failure {
            echo '=== PIPELINE FAILED ==='
            echo 'Rolling back changes...'
            sh """
                CURRENT_COLOR=\$(kubectl get service timer-app-service -n ${NAMESPACE} -o jsonpath='{.spec.selector.track}' 2>/dev/null || echo "blue")
                
                if [ "\$CURRENT_COLOR" = "green" ]; then
                    echo "Rolling back to blue"
                    kubectl patch service timer-app-service -n ${NAMESPACE} \
                        --type=merge -p '{"spec":{"selector":{"track":"blue"}}}'
                else
                    echo "Rolling back to green"
                    kubectl patch service timer-app-service -n ${NAMESPACE} \
                        --type=merge -p '{"spec":{"selector":{"track":"green"}}}'
                fi
            """
        }
        always {
            cleanWs()
        }
    }
}
