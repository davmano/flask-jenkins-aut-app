pipeline {
    agent any

    stages {
        stage('Build') {
            steps {
                sh 'docker build -t flask-app .'
            }
        }
        stage('Test') {
            steps {
                sh '''
                    docker rm -f flask-app-test || true
                    docker run -d --name flask-app-test -p 5000:5000 flask-app
                    for i in {1..10}; do
                      sleep 3
                      curl -f http://localhost:5000 && break || echo "Retrying..."
                    done
                    docker stop flask-app-test
                    docker rm flask-app-test
                '''
            }
        }
        stage('Push to Docker Hub') {
            steps {
                sh 'docker tag flask-app:latest davmano/flask-app:latest'
                withCredentials([usernamePassword(credentialsId: 'docker-hub', passwordVariable: 'DOCKER_HUB_PASSWORD', usernameVariable: 'DOCKER_HUB_USERNAME')]) {
                    sh '''
                        docker login -u $DOCKER_HUB_USERNAME -p $DOCKER_HUB_PASSWORD
                        docker push davmano/flask-app:latest
                    '''
                }
            }
        }
        stage('Deploy to Kubernetes') {
            steps {
                sh '''
                    kubectl config use-context minikube
                    kubectl set image deployment/flask-app flask-app=davmano/flask-app:latest --record
                '''
            }
        }
    }
}
