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
                    sleep 30
                    curl http://localhost:5000
                    docker stop flask-app-test
                    docker rm flask-app-test
                '''
            }
        }
        stage('Deploy') {
            steps {
                sh 'docker tag flask-app:latest <your-docker-hub-username>/flask-app:latest'
                withCredentials([usernamePassword(credentialsId: 'docker-hub', passwordVariable: 'DOCKER_HUB_PASSWORD', usernameVariable: 'DOCKER_HUB_USERNAME')]) {
                    sh '''
                        docker login -u $DOCKER_HUB_USERNAME -p $DOCKER_HUB_PASSWORD
                        docker push <your-docker-hub-username>/flask-app:latest
                    '''
                }
            }
        }
    }
}
