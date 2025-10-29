#!/usr/bin/env groovy

pipeline {
    agent any

    environment {
        IMAGE_NAME = 'sarathkrish1/timer-app'
        NAMESPACE  = 'timer-app'
        TAG        = ''
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    TAG = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
                    echo "Commit: ${TAG}"
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                docker build -t ${IMAGE_NAME}:${TAG} -t ${IMAGE_NAME}:latest .
                '''
            }
        }

        stage('Update Manifest') {
            steps {
                sh '''
                sed -i "s|image: .*|image: ${IMAGE_NAME}:${TAG}|" k8s/kustomization.yaml
                '''
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh '''
                kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
                kubectl apply -k k8s/
                '''
            }
        }

        stage('Wait for Rollout') {
            steps {
                sh '''
                LIVE=$(kubectl get svc timer-app-service -n ${NAMESPACE} -o jsonpath='{.spec.selector.track}' 2>/dev/null || echo blue)
                TARGET=$([ "$LIVE" = "blue" ] && echo green || echo blue)
                kubectl rollout status deployment/timer-app-${TARGET} -n ${NAMESPACE} --timeout=180s
                '''
            }
        }

        stage('Smoke Test') {
            steps {
                sh '''
                POD=$(kubectl get pod -n ${NAMESPACE} -l app=timer-app -o jsonpath='{.items[0].metadata.name}')
                kubectl port-forward -n ${NAMESPACE} pod/$POD 3000:3000 &
                PID=$!
                sleep 10
                curl -f http://localhost:3000 && kill $PID
                '''
            }
        }

        stage('Switch Traffic') {
            steps {
                sh '''
                LIVE=$(kubectl get svc timer-app-service -n ${NAMESPACE} -o jsonpath='{.spec.selector.track}')
                TARGET=$([ "$LIVE" = "blue" ] && echo green || echo blue)
                kubectl patch svc timer-app-service -n ${NAMESPACE} -p "{\\"spec\\":{\\"selector\\":{\\"track\\":\\"${TARGET}\\"}}}"
                kubectl scale deployment/timer-app-${LIVE} --replicas=1 -n ${NAMESPACE}
                '''
            }
        }

        stage('Verify via Ingress') {
            steps {
                sh '''
                IP=$(minikube ip 2>/dev/null || kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo 127.0.0.1)
                echo "$IP timer-app.local" | tee -a /tmp/hosts
                sleep 10
                curl -f http://timer-app.local && echo "App is LIVE at http://timer-app.local"
                '''
            }
        }

        stage('Cleanup') {
            steps {
                sh '''
                echo "Pipeline completed successfully!"
                '''
            }
        }
    }

    post {
        success {
            echo 'Blue/Green Deployment Successful!'
            echo 'Open: http://timer-app.local'
        }
        failure {
            echo 'Deployment Failed!'
        }
        always {
            cleanWs()
        }
    }
}