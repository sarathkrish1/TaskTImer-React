pipeline {
    agent any
    environment {
        IMAGE_NAME = 'sarathkrish1/timer-app'
        DOCKER_CLI = '/usr/bin/docker'  // <-- THIS IS KEY
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
                        echo "Logging in to Docker Hub..."
                        echo $PASS | ${DOCKER_CLI} login -u sarathkrish1 --password-stdin

                        echo "Building image: ${IMAGE_NAME}:${TAG}"
                        ${DOCKER_CLI} build -t ${IMAGE_NAME}:${TAG} -t ${IMAGE_NAME}:latest .

                        echo "Pushing ${IMAGE_NAME}:${TAG}..."
                        ${DOCKER_CLI} push ${IMAGE_NAME}:${TAG}

                        echo "Pushing ${IMAGE_NAME}:latest..."
                        ${DOCKER_CLI} push ${IMAGE_NAME}:latest

                        echo "Build & Push SUCCESS!"
                    '''
                }
            }
        }

        stage('Cleanup') {
            steps {
                sh '''
                    echo "Pruning dangling images..."
                    ${DOCKER_CLI} system prune -f || true
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
