pipeline {
    agent any

    environment {
        IMAGE_NAME = 'sarathkrish1/timer-app'
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
                withCredentials([usernamePassword(
                    credentialsId: 'docker-hub-credentials',
                    usernameVariable: 'USER',
                    passwordVariable: 'PASS'
                )]) {
                    sh '''
                        # FORCE TCP — THIS IS CRITICAL
                        export DOCKER_HOST=tcp://host.docker.internal:2375

                        echo "Using DOCKER_HOST: $DOCKER_HOST"

                        echo "=== DOCKER VERSION ==="
                        docker version

                        echo "=== LOGIN ==="
                        echo $PASS | docker login -u sarathkrish1 --password-stdin

                        echo "=== BUILD ==="
                        docker build -t ${IMAGE_NAME}:${TAG} -t ${IMAGE_NAME}:latest .

                        echo "=== PUSH ==="
                        docker push ${IMAGE_NAME}:${TAG}
                        docker push ${IMAGE_NAME}:latest

                        echo "SUCCESS: PUSHED!"
                    '''
                }
            }
        }
    }

    post {
        success {
            echo "LIVE ON DOCKER HUB!"
            echo "https://hub.docker.com/r/sarathkrish1/timer-app"
        }
        always { cleanWs() }
    }
}
