#!/usr/bin/env bash
set -euo pipefail

# =============== Helpers ===============
need_cmd() { command -v "$1" >/dev/null 2>&1; }
have_pkgmgr() { command -v "$1" >/dev/null 2>&1; }
os_like() {
  # returns 0 if /etc/os-release ID_LIKE contains the arg or ID matches
  local target="$1"
  if [[ -r /etc/os-release ]]; then
    . /etc/os-release
    [[ "${ID,,}" == *"$target"* ]] && return 0
    [[ "${ID_LIKE:-}" == *"$target"* ]] && return 0
  fi
  return 1
}

SUDO="$(command -v sudo || true)"
if [[ -z "${SUDO}" ]]; then SUDO=""; fi

JENKINS_USER="${JENKINS_USER:-jenkins}"   # override if different
INSTALL_MINIKUBE="${INSTALL_MINIKUBE:-0}" # set to 1 to install minikube too

# =============== Package deps ===============
install_base_packages_deb() {
  ${SUDO} apt-get update -y
  ${SUDO} apt-get install -y \
    ca-certificates curl gnupg lsb-release \
    apt-transport-https software-properties-common \
    jq
  # yq (binary)
  if ! need_cmd yq; then
    YQ_VER="v4.44.3"
    curl -fsSL "https://github.com/mikefarah/yq/releases/download/${YQ_VER}/yq_linux_amd64" -o /tmp/yq
    ${SUDO} install -m 0755 /tmp/yq /usr/local/bin/yq
  fi
}

install_base_packages_rhel() {
  ${SUDO} yum install -y \
    ca-certificates curl gnupg2 jq
  # yq (binary)
  if ! need_cmd yq; then
    YQ_VER="v4.44.3"
    curl -fsSL "https://github.com/mikefarah/yq/releases/download/${YQ_VER}/yq_linux_amd64" -o /tmp/yq
    ${SUDO} install -m 0755 /tmp/yq /usr/local/bin/yq
  fi
}

# =============== Docker ===============
install_docker_deb() {
  # Official Docker CE repo
  ${SUDO} install -m 0755 -d /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | ${SUDO} gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  ${SUDO} chmod a+r /etc/apt/keyrings/docker.gpg
  echo \
"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" | \
  ${SUDO} tee /etc/apt/sources.list.d/docker.list >/dev/null
  ${SUDO} apt-get update -y
  ${SUDO} apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  ${SUDO} systemctl enable --now docker || true
}

install_docker_rhel() {
  ${SUDO} yum install -y yum-utils
  ${SUDO} yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
  ${SUDO} yum install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
  ${SUDO} systemctl enable --now docker || true
}

post_docker() {
  if id "${JENKINS_USER}" >/dev/null 2>&1; then
    ${SUDO} usermod -aG docker "${JENKINS_USER}" || true
  fi
}

# =============== kubectl ===============
install_kubectl() {
  if need_cmd kubectl; then return 0; fi
  KUBECTL_VERSION="$(curl -fsSL https://dl.k8s.io/release/stable.txt)"
  curl -fsSLo /tmp/kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
  ${SUDO} install -m 0755 /tmp/kubectl /usr/local/bin/kubectl
}

# =============== Helm ===============
install_helm() {
  if need_cmd helm; then return 0; fi
  curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | ${SUDO} bash
}

# =============== kind ===============
install_kind() {
  if need_cmd kind; then return 0; fi
  KIND_VERSION="v0.23.0"
  curl -fsSLo /tmp/kind "https://github.com/kubernetes-sigs/kind/releases/download/${KIND_VERSION}/kind-linux-amd64"
  ${SUDO} install -m 0755 /tmp/kind /usr/local/bin/kind
}

# =============== kustomize ===============
install_kustomize() {
  if need_cmd kustomize; then return 0; fi
  KUSTOMIZE_VERSION="v5.4.3"
  curl -fsSL "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2F${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_linux_amd64.tar.gz" -o /tmp/kustomize.tgz
  tar -xzf /tmp/kustomize.tgz -C /tmp
  ${SUDO} install -m 0755 /tmp/kustomize /usr/local/bin/kustomize
}

# =============== minikube (optional) ===============
install_minikube() {
  if [[ "${INSTALL_MINIKUBE}" != "1" ]]; then return 0; fi
  if need_cmd minikube; then return 0; fi
  curl -fsSLo /tmp/minikube "https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64"
  ${SUDO} install -m 0755 /tmp/minikube /usr/local/bin/minikube
}

# =============== Main ===============
main() {
  echo "[*] Detecting OS and installing base packages..."
  if os_like debian || have_pkgmgr apt-get; then
    install_base_packages_deb
    echo "[*] Installing Docker (Debian/Ubuntu)..."
    install_docker_deb
  elif os_like rhel || have_pkgmgr yum || have_pkgmgr dnf; then
    install_base_packages_rhel
    echo "[*] Installing Docker (RHEL/CentOS/Rocky/Alma)..."
    install_docker_rhel
  else
    echo "Unsupported Linux distribution. Please extend this script." >&2
    exit 1
  fi
  post_docker

  echo "[*] Installing kubectl..."
  install_kubectl
  echo "[*] Installing Helm..."
  install_helm
  echo "[*] Installing kind..."
  install_kind
  echo "[*] Installing kustomize..."
  install_kustomize
  echo "[*] Installing minikube (optional flag INSTALL_MINIKUBE=1)..."
  install_minikube

  echo "[*] Versions:"
  docker --version || true
  kubectl version --client=true --output=yaml || true
  helm version || true
  kind version || true
  kustomize version || true
  yq --version || true
  jq --version || true
  if need_cmd minikube; then minikube version || true; fi

  echo "[✓] Bootstrap complete."
}

main "$@"
