pipeline {
    agent any

    environment {
        IMAGE_NAME = 'sarathkrish1/timer-app'
        DOCKER_API = 'http://host.docker.internal:2375'
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

        stage('Build & Push via API') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'docker-hub-credentials',
                    usernameVariable: 'USER',
                    passwordVariable: 'PASS'
                )]) {
                    sh '''
                        # 1. LOGIN VIA API
                        echo "Logging in to Docker Hub..."
                        curl -s -X POST "${DOCKER_API}/auth" \
                          -H "Content-Type: application/json" \
                          -d '{"username": "sarathkrish1", "password": "'"$PASS"'"}' > /dev/null

                        # 2. BUILD IMAGE
                        echo "Building image..."
                        tar -czf build-context.tar.gz .
                        curl -s -X POST "${DOCKER_API}/build?t=${IMAGE_NAME}:${TAG}&t=${IMAGE_NAME}:latest" \
                          --data-binary @build-context.tar.gz \
                          -H "Content-Type: application/x-tar" > build.log
                        cat build.log | grep -i "success"

                        # 3. PUSH IMAGE
                        echo "Pushing ${IMAGE_NAME}:${TAG}..."
                        curl -s -X POST "${DOCKER_API}/images/${IMAGE_NAME}:${TAG}/push" > push.log
                        cat push.log | grep -i "digest"

                        echo "PUSHED SUCCESSFULLY!"
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
