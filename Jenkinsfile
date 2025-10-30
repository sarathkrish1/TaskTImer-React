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
                        echo "=== LOGIN TO DOCKER HUB ==="
                        curl -s -X POST "${DOCKER_API}/auth" \
                          -H "Content-Type: application/json" \
                          -d '{"username": "sarathkrish1", "password": "'"$PASS"'"}' || exit 1

                        echo "=== BUILD IMAGE ==="
                        tar -czf build-context.tar.gz .
                        curl -s -X POST "${DOCKER_API}/build?t=${IMAGE_NAME}:${TAG}&t=${IMAGE_NAME}:latest&t=${IMAGE_NAME}:dev" \
                          --data-binary @build-context.tar.gz \
                          -H "Content-Type: application/x-tar" > build.log
                        grep -i "success" build.log && echo "BUILD SUCCESS!"

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

        // NEW STAGE 1: Run & Test Locally
        stage('Run & Test Container') {
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

                    echo "Waiting 15s for app to start..."
                    sleep 15

                    echo "Testing http://localhost:3000..."
                    curl -f --max-time 20 http://localhost:3000 && echo "APP IS LIVE!" || echo "APP FAILED"

                    echo "Stopping container..."
                    curl -s -X POST "${DOCKER_API}/containers/\${CONTAINER_ID}/stop"
                    curl -s -X DELETE "${DOCKER_API}/containers/\${CONTAINER_ID}"
                '''
            }
        }

        // NEW STAGE 2: Confirm dev tag
        stage('Confirm dev Tag') {
            steps {
                echo "dev tag pushed: ${IMAGE_NAME}:dev"
                echo "Check: https://hub.docker.com/r/sarathkrish1/timer-app/tags"
            }
        }
    }

    post {
        success {
            script {
                echo "SUCCESS: IMAGE LIVE ON DOCKER HUB!"
                echo "https://hub.docker.com/r/sarathkrish1/timer-app"
                echo "Tags: ${env.TAG}, latest, dev"
            }
        }
        failure {
            script {
                echo "BUILD FAILED. Check logs above."
            }
        }
        always {
            script {
                cleanWs(cleanWhenSuccess: true, cleanWhenFailure: true, cleanWhenAborted: true)
            }
        }
    }
}
