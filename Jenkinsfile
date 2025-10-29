pipeline {
    agent any
    parameters {
        string(name: 'MINIKUBE_IP', defaultValue: '192.168.49.2', description: 'Run `minikube ip` and paste here')
    }
    environment {
        IMAGE_NAME = 'sarathkrish1/timer-app'
        NAMESPACE  = 'timer-app'
    }
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script { env.TAG = sh(returnStdout: true, script: 'git rev-parse --short HEAD').trim() }
            }
        }
        stage('Build & Push') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                    sh '''
                    echo $PASS | docker login -u $USER --password-stdin
                    docker build -t ${IMAGE_NAME}:${TAG} -t ${IMAGE_NAME}:latest .
                    docker push ${IMAGE_NAME}:${TAG}
                    docker push ${IMAGE_NAME}:latest
                    '''
                }
            }
        }
        stage('Update Manifest') {
            steps { sh "sed -i 's|image: .*|image: ${IMAGE_NAME}:${TAG}|' k8s/kustomization.yaml" }
        }
        stage('Deploy') {
            steps {
                withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
                    sh '''
                    mkdir -p ~/.kube
                    cp \$KUBECONFIG ~/.kube/config
                    kubectl create ns ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
                    kubectl apply -k k8s/
                    '''
                }
            }
        }
        stage('Wait') {
            steps {
                withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
                    sh '''
                    cp \$KUBECONFIG ~/.kube/config
                    LIVE=\$(kubectl get svc timer-app-service -n ${NAMESPACE} -o jsonpath='{.spec.selector.track}' 2>/dev/null || echo blue)
                    TARGET=\$(if [ "\$LIVE" = "blue" ]; then echo green; else echo blue; fi)
                    kubectl rollout status deployment/timer-app-\$TARGET -n ${NAMESPACE} --timeout=180s
                    '''
                }
            }
        }
        stage('Smoke Test') {
            steps {
                withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
                    sh '''
                    cp \$KUBECONFIG ~/.kube/config
                    POD=\$(kubectl get pod -n ${NAMESPACE} -l app=timer-app -o jsonpath='{.items[0].metadata.name}')
                    kubectl port-forward -n ${NAMESPACE} pod/\$POD 3000:3000 > /dev/null 2>&1 &
                    sleep 10
                    curl -f http://localhost:3000 && kill \$!
                    '''
                }
            }
        }
        stage('Switch') {
            steps {
                withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
                    sh '''
                    cp \$KUBECONFIG ~/.kube/config
                    LIVE=\$(kubectl get svc timer-app-service -n ${NAMESPACE} -o jsonpath='{.spec.selector.track}')
                    TARGET=\$(if [ "\$LIVE" = "blue" ]; then echo green; else echo blue; fi)
                    kubectl patch svc timer-app-service -n ${NAMESPACE} -p "{\\"spec\\":{\\"selector\\":{\\"track\\":\\"\$TARGET\\"}}}"
                    '''
                }
            }
        }
        stage('Verify') {
            steps {
                sh '''
                echo "${MINIKUBE_IP} timer-app.local" >> /tmp/hosts
                curl -f http://timer-app.local
                '''
            }
        }
        stage('Cleanup') {
            steps { echo 'ALL GREEN!' }
        }
    }
    post {
        success { echo 'DEPLOY SUCCESS! ALL STAGES GREEN!' }
        always { cleanWs() }
    }
}