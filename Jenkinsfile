pipeline {
    agent any
    environment {
        IMAGE_NAME = 'sarathkrish1/timer-app'
        DOCKER_HOST = 'tcp://host.docker.internal:2375'  // <-- THIS IS KEY
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
                        echo "Testing Docker connection..."
                        docker version

                        echo "Logging in to Docker Hub..."
                        echo $PASS | docker login -u sarathkrish1 --password-stdin

                        echo "Building image: ${IMAGE_NAME}:${TAG}"
                        docker build -t ${IMAGE_NAME}:${TAG} -t ${IMAGE_NAME}:latest .

                        echo "Pushing ${IMAGE_NAME}:${TAG}..."
                        docker push ${IMAGE_NAME}:${TAG}

                        echo "Pushing ${IMAGE_NAME}:latest..."
                        docker push ${IMAGE_NAME}:latest

                        echo "Build & Push SUCCESS!"
                    '''
                }
            }
        }

        stage('Cleanup') {
            steps {
                sh '''
                    echo "Pruning dangling images..."
                    docker system prune -f || true
                '''
                echo 'CI/CD PIPELINE COMPLETE!'
            }
        }
    }

    post {
        success {
            echo "SUCCESS: IMAGE LIVE ON DOCKER HUB!"
            echo "https://hub.docker.com/r/sarathkrish1/timer-app/tags"
        }
        failure { echo 'Build failed!' }
        always { cleanWs() }
    }
}
