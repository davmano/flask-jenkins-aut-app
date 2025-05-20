# 🧪 Flask Jenkins CI/CD Pipeline

This project demonstrates a complete **CI/CD pipeline** for deploying a simple **Flask web application** using:

* 🐳 Docker
* 🔧 Jenkins
* ☸️ Kubernetes (via Minikube)
* ☁️ Docker Hub

GitHub Repo ➡️ [flask-jenkins-aut-app](https://github.com/davmano/flask-jenkins-aut-app)

---

## 🔍 Project Overview

The pipeline performs the following automated steps:

1. **Clones** the Flask app from GitHub.
2. **Builds** a Docker image of the Flask app.
3. **Runs and tests** the container to ensure the app is healthy.
4. **Pushes** the image to Docker Hub.
5. **Deploys** the updated image to a Kubernetes cluster running locally with Minikube.

---

## 🛠️ Tech Stack

| Component          | Tool/Service Used     |
| ------------------ | --------------------- |
| Language           | Python (Flask)        |
| CI/CD              | Jenkins               |
| Containerization   | Docker                |
| Container Registry | Docker Hub            |
| Orchestration      | Kubernetes (Minikube) |

---

## 🔧 Pipeline Stages (Jenkinsfile)

### 1. Checkout Source

* Pulls code from GitHub repo.

### 2. Build Docker Image

```sh
docker build -t flask-app .
```

* Builds the app using a Dockerfile based on `python:3.9-slim`.

### 3. Run and Test Container

```sh
docker run -d --name flask-app-test -p 5000:5000 flask-app
curl -f http://localhost:5000
```

* Confirms the app starts and responds properly.

### 4. Push to Docker Hub

```sh
docker tag flask-app:latest davmano/flask-app:latest
docker login -u davmano -p $DOCKER_HUB_PASSWORD
docker push davmano/flask-app:latest
```

* Pushes the tested image to Docker Hub.

### 5. Deploy to Kubernetes

```sh
kubectl config use-context minikube
kubectl set image deployment/flask-app flask-app=davmano/flask-app:latest --record
```

* Updates the Kubernetes deployment with the latest Docker image.

---

## 🧱 Key Configuration Steps

* Jenkins has Docker installed and is added to the `docker` group.
* Minikube is running locally and accessible via Jenkins.
* Jenkins has read access to Kubernetes kubeconfig and certs.

```sh
sudo mkdir -p /var/lib/jenkins/.kube
sudo cp ~/.kube/config /var/lib/jenkins/.kube/config
sudo chown -R jenkins:jenkins /var/lib/jenkins/.kube
```

---

## 🔐 Credentials

* Docker Hub credentials stored in Jenkins using `withCredentials`.
* Kubeconfig manually made accessible to Jenkins user.

---

## 🧠 Learning Highlights

* Built a real-world CI/CD pipeline from scratch.
* Understood Docker image creation, tagging, and container testing.
* Deployed containers into Kubernetes using command-line tools.
* Managed Jenkins security, permissions, and pipeline scripting.

---

## 🚀 Next Steps

* Replace `kubectl set image` with YAML-based `kubectl apply -f`.
* Add automated rollback and rollout status checks.
* Integrate with GitHub webhooks for auto-triggering builds.
* Implement Slack/email notifications.

---

## 📸 Screenshot

![pipeline-screenshot](https://github.com/user-attachments/assets/d29e13b9-f0f0-4547-a68d-f01873eb57a3)

![k8s-screenshot](https://github.com/user-attachments/assets/9b69ca96-562d-4f62-b257-edcabf7e7a3c)

---

## 👨‍💻 Author

**David Mano**
DevOps Engineer | Cloud Enthusiast | CI/CD Practitioner

---

## 📂 License

MIT License

