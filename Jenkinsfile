pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "davmano/flask-app"
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', url: 'https://github.com/davmano/flask-jenkins-aut-app.git'
                script {
                    COMMIT_ID = sh(script: "git rev-parse --short HEAD || echo latest", returnStdout: true).trim()
                    echo "Commit ID: ${COMMIT_ID}"
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                    docker build -t ${DOCKER_IMAGE}:${COMMIT_ID} -t ${DOCKER_IMAGE}:latest .
                """
            }
        }

        stage('Test Image') {
            steps {
                sh """
                    TEST_PORT=5001
                    docker rm -f flask-app-test || true
                    docker run -d --name flask-app-test -p $TEST_PORT:5000 ${DOCKER_IMAGE}:${COMMIT_ID}
                    for i in {1..10}; do
                        sleep 3
                        curl -f http://localhost:$TEST_PORT && break || echo "Retrying..."
                    done
                    docker stop flask-app-test
                    docker rm flask-app-test
                """
            }
        }

        stage('Push to Docker Hub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-hub', usernameVariable: 'DOCKER_HUB_USERNAME', passwordVariable: 'DOCKER_HUB_PASSWORD')]) {
                    sh """
                        echo $DOCKER_HUB_PASSWORD | docker login -u $DOCKER_HUB_USERNAME --password-stdin
                        docker push ${DOCKER_IMAGE}:${COMMIT_ID}
                        docker push ${DOCKER_IMAGE}:latest
                    """
                }
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                withCredentials([file(credentialsId: 'kind-kubeconfig', variable: 'KUBECONFIG_FILE')]) {
                    sh """
                        export KUBECONFIG=$KUBECONFIG_FILE
                        kubectl get nodes
                        kubectl set image deployment/flask-app flask-app=${DOCKER_IMAGE}:${COMMIT_ID} --record
                        kubectl rollout status deployment/flask-app
                    """
                }
            }
        }
    }

    post {
        always {
            sh 'docker system prune -af || true'
        }
        failure {
            echo "❌ Pipeline failed. Check logs."
        }
        success {
            echo "✅ Pipeline completed successfully."
        }
    }
}
