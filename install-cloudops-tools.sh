#!/bin/bash

set -e

echo "===================================="
echo "Cloud Workstation Setup"
echo "Amazon Linux 2023"
echo "===================================="

echo "[1/8] Updating System..."
sudo dnf update -y

echo "[2/8] Installing base packages..."
sudo dnf install -y \
	git \
	wget \
	unzip \
	jq \
	tar \
	gzip \
	vim \
	nano \
	tree \
	python3 \
	python3-pip \
	openssl

echo "[3/8] Installing AWS CLI V2..."
if ! command -v aws > /dev/null 2>&1; then
	cd /tmp

	curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" \
		-o awscliv2.zip
	rm -rf aws awscliv2.zip.tmp
	unzip -q awscliv2.zip

	sudo ./aws/install

	rm -rf aws awscliv2.zip
fi

echo "[4/8] Installing Terraform..."

if ! command -v terraform > /dev/null 2>&1; then
	TERRAFORM_VERSION=$(curl -s https://checkpoint-api.hashicorp.com/v1/check/terraform \
        | jq -r '.current_version')
	cd /tmp
	curl -fsSLO \
        "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip"

    unzip -o \
        "terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
    sudo mv terraform /usr/local/bin/

    rm -rf terraform_${TERRAFORM_VERSION}_linux_amd64.zip
fi

echo "[5/8] Installing Docker..."

sudo dnf install -y docker

sudo systemctl enable docker
sudo systemctl start docker

sudo usermod -aG docker ssm-user

echo "[6/8] Installing kubectl..."

if ! command -v kubectl >/dev/null 2>&1; then

	KUBECTL_VERSION=$(curl -L -s \
		https://dl.k8s.io/release/stable.txt)

	curl -LO \
		"https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
	chmod +x kubectl

	sudo mv kubectl /usr/local/bin/

fi

echo "[7/8] Installing Helm..."

if ! command -v helm >/dev/null 2>&1; then

    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 \
        | bash
fi

echo "[8/8] Installing useful Kubernetes/AWS utilities..."

# yq
if ! command -v yq >/dev/null 2>&1; then

    sudo wget -q \
        https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 \
        -O /usr/local/bin/yq

    sudo chmod +x /usr/local/bin/yq

fi

echo ""
echo "======================================"
echo " Installation completed"
echo "======================================"

echo ""
echo "Installed versions:"
echo "-------------------"

git --version
aws --version
terraform --version | head -1
docker --version
kubectl version --client
helm version --short
yq --version
python3 --version
pip3 --version

echo ""
echo "Docker group:"
echo "--------------"
groups

echo ""
echo "IMPORTANT:"
echo "Log out and reconnect through SSM"
echo "for Docker group permissions to take effect."

echo ""
echo "After reconnecting run:"
echo "docker ps"
echo ""

