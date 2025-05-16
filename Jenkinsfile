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
                    # Kill any container using port 5000 (if leftover from previous builds)
            PORT_5000_PID=$(docker ps --filter "publish=5000" -q)
            if [ ! -z "$PORT_5000_PID" ]; then
              docker rm -f $PORT_5000_PID || true
            fi

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
