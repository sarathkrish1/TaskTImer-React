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

        stage('Build & Push via Docker API') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'docker-hub-credentials',
                    usernameVariable: 'USER',
                    passwordVariable: 'PASS'
                )]) {
                    sh '''
                        echo "=== LOGIN TO DOCKER HUB VIA API ==="
                        curl -s -X POST "${DOCKER_API}/auth" \
                          -H "Content-Type: application/json" \
                          -d '{"username": "sarathkrish1", "password": "'"$PASS"'"}'

                        echo "=== BUILD IMAGE ==="
                        tar -czf build-context.tar.gz .
                        curl -s -X POST "${DOCKER_API}/build?t=${IMAGE_NAME}:${TAG}&t=${IMAGE_NAME}:latest" \
                          --data-binary @build-context.tar.gz \
                          -H "Content-Type: application/x-tar" > build.log
                        grep -i "success" build.log && echo "BUILD SUCCESS!"

                        echo "=== PUSH IMAGE ==="
                        curl -s -X POST "${DOCKER_API}/images/${IMAGE_NAME}:${TAG}/push" > push.log
                        grep -i "digest" push.log && echo "PUSH SUCCESS!"

                        echo "=== DONE ==="
                        rm -f build-context.tar.gz build.log push.log
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
