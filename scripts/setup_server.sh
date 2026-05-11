#!/bin/bash
# =============================================================================
# setup_server.sh — QuickBite Server Setup
# Tested on: Ubuntu 22.04 LTS / 24.04 LTS
# Run as root or with sudo: sudo bash setup_server.sh
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log()    { echo -e "${GREEN}[INFO]${NC}  $*"; }
warn()   { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()  { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# ── Must run as root ──────────────────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
  error "Please run this script as root: sudo bash $0"
fi

log "===== QuickBite Server Setup Started ====="
log "Host: $(hostname) | OS: $(lsb_release -ds)"

# =============================================================================
# STEP 1 — Update & upgrade Ubuntu
# =============================================================================
log "--- Step 1: Updating Ubuntu packages ---"
export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get upgrade -y
apt-get install -y \
  curl \
  wget \
  gnupg \
  ca-certificates \
  lsb-release \
  apt-transport-https \
  software-properties-common \
  git \
  unzip \
  net-tools
log "System updated successfully."

# =============================================================================
# STEP 2 — Install Docker
# =============================================================================
log "--- Step 2: Installing Docker ---"

# Remove old/conflicting Docker packages
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
  apt-get remove -y "$pkg" 2>/dev/null || true
done

# Add Docker's official GPG key
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
  https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update -y
apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

# Enable and start Docker
systemctl enable docker
systemctl start docker

# Add jenkins and ubuntu users to docker group (created later, pre-adding is fine)
usermod -aG docker ubuntu   2>/dev/null || true

log "Docker $(docker --version) installed."

# =============================================================================
# STEP 3 — Install Docker Compose (standalone v2 CLI)
# =============================================================================
log "--- Step 3: Installing Docker Compose (standalone) ---"

COMPOSE_VERSION=$(curl -fsSL https://api.github.com/repos/docker/compose/releases/latest \
  | grep '"tag_name"' | sed 's/.*"tag_name": "\(.*\)".*/\1/')

curl -fsSL \
  "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-$(uname -m)" \
  -o /usr/local/bin/docker-compose

chmod +x /usr/local/bin/docker-compose
ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

log "Docker Compose $(docker-compose --version) installed."

# =============================================================================
# STEP 4 — Install Jenkins (LTS)
# =============================================================================
log "--- Step 4: Installing Jenkins LTS ---"

# Jenkins requires Java 17 or 21
apt-get install -y fontconfig openjdk-17-jre
java -version

# Add Jenkins repository
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key \
  | tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null

echo \
  "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/" \
  > /etc/apt/sources.list.d/jenkins.list

apt-get update -y
apt-get install -y jenkins

# Add jenkins to docker group so it can run docker commands
usermod -aG docker jenkins

# Enable and start Jenkins
systemctl enable jenkins
systemctl start jenkins

log "Jenkins installed and started."

# =============================================================================
# STEP 5 — Install kubectl
# =============================================================================
log "--- Step 5: Installing kubectl ---"

KUBECTL_VERSION=$(curl -fsSL https://dl.k8s.io/release/stable.txt)
curl -fsSL "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
  -o /usr/local/bin/kubectl
chmod +x /usr/local/bin/kubectl

log "kubectl $(kubectl version --client --short 2>/dev/null || kubectl version --client) installed."

# =============================================================================
# STEP 6 — Firewall rules (ufw)
# =============================================================================
log "--- Step 6: Configuring firewall ---"

if command -v ufw &>/dev/null; then
  ufw allow OpenSSH
  ufw allow 8080/tcp   # Jenkins UI
  ufw allow 30001/tcp  # QuickBite frontend (K8s NodePort)
  ufw allow 30002/tcp  # QuickBite backend  (K8s NodePort)
  ufw allow 3000/tcp   # Docker Compose frontend
  ufw allow 5000/tcp   # Docker Compose backend
  ufw --force enable
  log "UFW firewall configured."
else
  warn "ufw not found — skipping firewall setup."
fi

# =============================================================================
# DONE
# =============================================================================
log ""
log "===== Setup Complete ====="
log ""
log "  Docker   : $(docker --version)"
log "  Compose  : $(docker-compose --version)"
log "  Jenkins  : $(systemctl is-active jenkins)"
log "  kubectl  : $(kubectl version --client --short 2>/dev/null | head -1)"
log ""
log "  Jenkins UI      : http://$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}'):8080"
log "  Jenkins password: $(cat /var/lib/jenkins/secrets/initialAdminPassword 2>/dev/null || echo 'run: sudo cat /var/lib/jenkins/secrets/initialAdminPassword')"
log ""
warn "IMPORTANT: Log out and back in (or run 'newgrp docker') for docker group to take effect."
log "============================="
