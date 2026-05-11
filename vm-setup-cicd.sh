#!/usr/bin/env bash

set -euo pipefail

echo
echo "### Updating system packages..."
sudo apt-get update -y
sudo apt-get upgrade -y

echo "Installing prerequisites..."
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    software-properties-common \
    unzip

echo
echo "###Installing Git..."
sudo apt-get install -y git

echo "Installing Docker..."

sudo install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) \
  signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y

sudo apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

echo "Adding current user to docker group..."
sudo usermod -aG docker "$USER"

echo
echo "### Installing kubectl..."
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.35/deb/Release.key | \
  sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.35/deb/ /" | \
  sudo tee /etc/apt/sources.list.d/kubernetes.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y kubectl

echo
echo "###Installing Python 3.12 and pip..."

sudo add-apt-repository ppa:deadsnakes/ppa -y
sudo apt-get update -y

sudo apt-get install -y \
    python3.12 \
    python3.12-venv \
    python3.12-dev \
    python3-pip

echo
echo "### Installing Terraform..."

curl -fsSL https://apt.releases.hashicorp.com/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/hashicorp-archive-keyring.gpg

echo "deb [signed-by=/etc/apt/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com \
$(lsb_release -cs) main" | \
    sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt-get update -y
sudo apt-get install -y terraform

echo
echo "### Installing Helm..."
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

echo
echo "### Install SCW CLI..."
VERSION="${1:-v2.55.0}"
BASE_URL="https://github.com/scaleway/scaleway-cli/releases/download"

ARCH="$(uname -m)"

case "$ARCH" in
    x86_64|amd64)
        PLATFORM="linux_amd64"
        ;;
    aarch64|arm64)
        PLATFORM="linux_arm64"
        ;;
    *)
        echo "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

BINARY="scaleway-cli_${VERSION#v}_${PLATFORM}"
URL="${BASE_URL}/${VERSION}/${BINARY}"

echo "Detected architecture: $ARCH"
echo "Downloading: $URL"

curl -fL -o scw "$URL"

chmod +x scw
sudo mv scw /usr/local/bin/scw


echo
echo "### Installation complete. Versions installed:"
echo "------------------------------------------------"
docker --version || true
git --version || true
kubectl version --client || true
python3.12 --version || true
pip3 --version || true
terraform version || true
helm version || true
scw version || true