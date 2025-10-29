pipeline {
    agent any

    environment {
        IMAGE_NAME = 'sarathkrish1/timer-app'
        DOCKER_HOST = 'tcp://host.docker.internal:2375'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.TAG = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
                    echo "Building image: ${IMAGE_NAME}:${TAG}"
                }
            }
        }

        stage('Build & Push') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'docker-hub-credentials',
                    usernameVariable: 'USER',
                    passwordVariable: 'PASS'
                )]) {
                    sh '''
                        # Force TCP connection
                        export DOCKER_HOST=tcp://host.docker.internal:2375

                        echo "=== DOCKER VERSION ==="
                        docker version

                        echo "=== LOGIN TO DOCKER HUB ==="
                        echo $PASS | docker login -u sarathkrish1 --password-stdin

                        echo "=== BUILD DOCKER IMAGE ==="
                        docker build -t ${IMAGE_NAME}:${TAG} -t ${IMAGE_NAME}:latest .

                        echo "=== PUSH TO DOCKER HUB ==="
                        docker push ${IMAGE_NAME}:${TAG}
                        docker push ${IMAGE_NAME}:latest

                        echo "SUCCESS: IMAGE PUSHED!"
                    '''
                }
            }
        }

        stage('Cleanup') {
            steps {
                sh '''
                    docker system prune -f || true
                '''
                echo "CI/CD PIPELINE COMPLETE!"
            }
        }
    }

    post {
        success {
            echo "LIVE ON DOCKER HUB!"
            echo "https://hub.docker.com/r/sarathkrish1/timer-app/tags"
        }
        failure {
            echo "Build failed. Check Docker Desktop TCP settings."
        }
        always {
            cleanWs()
        }
    }
}
