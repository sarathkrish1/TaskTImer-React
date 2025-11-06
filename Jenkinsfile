pipeline {
    agent any

    environment {
        IMAGE_NAME = 'sarathkrish1/timer-app'
        DOCKER_API = 'http://host.docker.internal:2375'
    }

    stages {
        stage('Checkout Code') {
            steps {
                checkout scm
                script {
                    env.TAG = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim()
                    echo "Build Tag: ${env.TAG}"
                }
            }
        }

        stage('Build Docker Image Python + MediaPipe + OpenCV') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'docker-hub-credentials',
                    usernameVariable: 'USER',
                    passwordVariable: 'PASS'
                )]) {
                    sh '''
                        echo "=== LOGIN TO DOCKER HUB (USING PAT) ==="
                        curl -s -X POST "${DOCKER_API}/auth" \
                          -H "Content-Type: application/json" \
                          -d "{\"username\": \"$USER\", \"password\": \"$PASS\"}" || exit 1

                        echo "=== BUILD IMAGE ==="
                        tar -czf build-context.tar.gz . || true
                        curl -s -X POST "${DOCKER_API}/build?t=${IMAGE_NAME}:${TAG}&t=${IMAGE_NAME}:latest&t=${IMAGE_NAME}:dev" \
                          --data-binary @build-context.tar.gz \
                          -H "Content-Type: application/x-tar" > build.log
                        grep -i "success" build.log && echo "BUILD SUCCESS!" || exit 1

                        echo "=== PUSH TAGS ==="
                        for tag in ${TAG} latest dev; do
                            echo "Pushing ${IMAGE_NAME}:\${tag}..."
                            curl -s -X POST "${DOCKER_API}/images/${IMAGE_NAME}:\${tag}/push" > "push-\${tag}.log"
                            grep -i "digest" "push-\${tag}.log" && echo "PUSH \${tag} SUCCESS!"
                        done

                        rm -f build-context.tar.gz build.log push-*.log
                    '''
                }
            }
        }

        stage('Deploy to AWS') {
            steps {
                sh '''
                    echo "=== START TEST CONTAINER ==="
                    CONTAINER_ID=$(curl -s -X POST "${DOCKER_API}/containers/create?name=test-timer" \
                      -H "Content-Type: application/json" \
                      -d '{
                        "Image": "${IMAGE_NAME}:${TAG}",
                        "ExposedPorts": {"3000/tcp": {}},
                        "HostConfig": { "PortBindings": { "3000/tcp": [{ "HostPort": "3000" }] } }
                      }' | jq -r .Id)

                    curl -s -X POST "${DOCKER_API}/containers/\${CONTAINER_ID}/start"
                    sleep 15
                    curl -f --max-time 20 http://localhost:3000 && echo "APP IS LIVE!" || echo "APP FAILED"
                    curl -s -X POST "${DOCKER_API}/containers/\${CONTAINER_ID}/stop"
                    curl -s -X DELETE "${DOCKER_API}/containers/\${CONTAINER_ID}"
                '''
            }
        }

        stage('Monitor with CloudWatch') {
            steps {
                echo "dev tag: ${IMAGE_NAME}:dev"
            }
        }
    }

    post {
        success { script { echo "LIVE: https://hub.docker.com/r/${IMAGE_NAME}" } }
        always { script { cleanWs() } }
    }
}
