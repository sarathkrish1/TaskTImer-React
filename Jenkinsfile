pipeline {
    agent any
    parameters {
        string(name: 'MINIKUBE_IP', defaultValue: '192.168.49.2', description: 'Run `minikube ip` and paste here')
    }
    environment {
        IMAGE_NAME = 'sarathkrish1/timer-app'
        NAMESPACE = 'timer-app'
    }
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script { 
                    env.TAG = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim() 
                    echo "Build Tag: ${env.TAG}"
                }
            }
        }

        stage('Build & Push') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                    sh '''
                        echo "Logging in as sarathkrish1..."
                        echo $PASS | /usr/bin/docker login -u sarathkrish1 --password-stdin

                        echo "Building image: ${IMAGE_NAME}:${TAG}"
                        /usr/bin/docker build -t ${IMAGE_NAME}:${TAG} -t ${IMAGE_NAME}:latest .

                        echo "Pushing ${IMAGE_NAME}:${TAG}..."
                        /usr/bin/docker push ${IMAGE_NAME}:${TAG}

                        echo "Pushing ${IMAGE_NAME}:latest..."
                        /usr/bin/docker push ${IMAGE_NAME}:latest

                        echo "Push complete!"
                    '''
                }
            }
        }

        stage('Update Manifest') {
            steps { 
                sh "sed -i 's|image: .*|image: ${IMAGE_NAME}:${TAG}|' k8s/kustomization.yaml" 
                echo "Updated k8s/kustomization.yaml with ${IMAGE_NAME}:${TAG}"
            }
        }

        stage('Deploy') {
            when { expression { return false } } // Skip K8s for now
            steps {
                withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
                    sh '''
                        mkdir -p ~/.kube
                        cp $KUBECONFIG ~/.kube/config
                        kubectl create ns ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
                        kubectl apply -k k8s/
                    '''
                }
            }
        }

        stage('Wait') { when { expression { return false } } steps { echo 'Skipped' } }
        stage('Smoke Test') { when { expression { return false } } steps { echo 'Skipped' } }
        stage('Switch') { when { expression { return false } } steps { echo 'Skipped' } }
        stage('Verify') { when { expression { return false } } steps { echo 'Skipped' } }

        stage('Cleanup') {
            steps { 
                sh '''
                    echo "Cleaning up dangling images..."
                    /usr/bin/docker system prune -f || true
                '''
                echo 'ALL GREEN! Docker Build & Push SUCCESS!'
            }
        }
    }

    post {
        success { 
            echo "SUCCESS: DEPLOYED TO DOCKER HUB!"
            echo "https://hub.docker.com/r/sarathkrish1/timer-app"
        }
        failure { echo 'Build failed!' }
        always { cleanWs() }
    }
}
