#!/usr/bin/env groovy
pipeline {
    agent {
        docker {
            image 'jenkins/inbound-agent:latest-jdk11'
            args '-v /var/run/docker.sock:/var/run/docker.sock --user root'
        }
    }

    environment {
        DOCKER_REGISTRY = 'docker.io'
        IMAGE_NAME      = 'sarathkrish1/timer-app'
        NAMESPACE       = 'timer-app'
        KUBECTL_VERSION = 'v1.29.0'
    }

    stages {
        stage('Install Tools') {
            steps {
                sh '''
                    curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
                    chmod +x kubectl
                    mv kubectl /usr/local/bin/
                    kubectl version --client

                    curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
                    install minikube-linux-amd64 /usr/local/bin/minikube
                    minikube version
                '''
            }
        }

        stage('Start Minikube') {
            steps {
                sh '''
                    minikube start --driver=docker --cpus=2 --memory=4096 --kubernetes-version=${KUBECTL_VERSION}
                    minikube addons enable ingress
                    minikube status
                '''
            }
        }

        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.SHORT_COMMIT = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
                    echo "Commit: ${env.SHORT_COMMIT}"
                }
            }
        }

        stage('Build Image') {
            steps {
                sh '''
                    eval $(minikube docker-env)
                    docker build -t ${IMAGE_NAME}:${SHORT_COMMIT} -t ${IMAGE_NAME}:latest .
                '''
            }
        }

        stage('Determine Target Color') {
            steps {
                script {
                    sh "kubectl create ns ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -"
                    def live = sh(returnStdout: true, script: "kubectl get svc timer-app-service -n ${NAMESPACE} -o jsonpath='{.spec.selector.track}' || echo ''").trim()
                    env.LIVE_COLOR = live ?: 'blue'
                    env.TARGET_COLOR = env.LIVE_COLOR == 'blue' ? 'green' : 'blue'
                    echo "Switching from ${env.LIVE_COLOR} → ${env.TARGET_COLOR}"
                }
            }
        }

        stage('Update Manifests') {
            steps {
                sh '''
                    sed -i "s|image: .*|image: ${IMAGE_NAME}:${SHORT_COMMIT}|" k8s/kustomization.yaml
                '''
            }
        }

        stage('Deploy Idle Color') {
            steps {
                sh '''
                    kubectl apply -k k8s/
                    kubectl rollout status deployment/timer-app-${TARGET_COLOR} -n ${NAMESPACE} --timeout=180s
                '''
            }
        }

        stage('Smoke Test') {
            steps {
                sh '''
                    POD=$(kubectl get pod -n ${NAMESPACE} -l track=${TARGET_COLOR} -o jsonpath='{.items[0].metadata.name}')
                    kubectl port-forward -n ${NAMESPACE} pod/$POD 3000:3000 &
                    PID=$!
                    sleep 8
                    curl -f http://localhost:3000 || (kill $PID; exit 1)
                    kill $PID
                '''
            }
        }

        stage('Switch Traffic') {
            steps {
                sh '''
                    kubectl patch svc timer-app-service -n ${NAMESPACE} -p "{\"spec\":{\"selector\":{\"track\":\"${TARGET_COLOR}\"}}}"
                '''
            }
        }

        stage('Scale Down Old') {
            steps {
                sh '''
                    kubectl scale deployment/timer-app-${LIVE_COLOR} --replicas=1 -n ${NAMESPACE}
                '''
            }
        }

        stage('Verify Ingress') {
            steps {
                script {
                    def ip = sh(returnStdout: true, script: 'minikube ip').trim()
                    sh "echo '$ip timer-app.local' >> /etc/hosts"
                    sh 'sleep 10'
                    sh 'curl -f http://timer-app.local'
                }
            }
        }
    }

    post {
        always { cleanWs() }
        success { echo 'Blue/Green Deployed!' }
        failure { echo 'Failed – no rollback in demo mode' }
    }
}