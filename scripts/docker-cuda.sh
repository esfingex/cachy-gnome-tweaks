#!/bin/bash
# ==============================================================================
#   cachy-gnome-tweaks - scripts/docker-cuda.sh
#   Purpose: Install Docker stack and configure NVIDIA CUDA container toolkit
# ==============================================================================
set -euo pipefail

# ANSI color codes
CYAN="\e[1;36m"
GREEN="\e[1;32m"
YELLOW="\e[1;33m"
RED="\e[1;31m"
RESET="\e[0m"

log_info() { echo -e "${CYAN}[*] $1${RESET}"; }
log_success() { echo -e "${GREEN}[+] $1${RESET}"; }
log_warn() { echo -e "${YELLOW}[!] $1${RESET}"; }
log_error() { echo -e "${RED}[ERROR] $1${RESET}" >&2; }

# Pre-checks
if [ "$EUID" -ne 0 ]; then
    log_error "This script module must be run as root (sudo)."
    exit 1
fi

TARGET_USER="${SUDO_USER:-$USER}"

log_info "Initiating Docker Engine & NVIDIA CUDA container toolkit setup..."

# 1. Install Docker, Docker Compose, and NVIDIA Container Toolkit
log_info "Installing docker, docker-compose, and nvidia-container-toolkit via pacman..."
pacman -S --needed --noconfirm \
    docker \
    docker-compose \
    nvidia-container-toolkit || log_warn "Could not install all container engine packages cleanly."

# 2. Start and enable Docker service daemon
log_info "Activating and enabling Docker systemd daemon..."
systemctl enable --now docker.service 2>/dev/null || true

# 3. Add user to docker group for non-root runtime permissions
log_info "Registering user '${TARGET_USER}' in 'docker' group..."
if getent group docker >/dev/null; then
    usermod -aG docker "$TARGET_USER"
    log_success "Added ${TARGET_USER} to docker group."
else
    groupadd docker 2>/dev/null || true
    usermod -aG docker "$TARGET_USER"
    log_success "Created docker group and registered ${TARGET_USER}."
fi

# 4. Configure NVIDIA Container Toolkit runtime hooks for Docker
log_info "Configuring NVIDIA container runtime hooks inside Docker daemon configuration..."
if command -v nvidia-ctk &>/dev/null; then
    # Generate/merge runtime parameters into /etc/docker/daemon.json
    if nvidia-ctk runtime configure --runtime=docker >>/tmp/cachy-gnome-tweaks.log 2>&1; then
        log_success "NVIDIA container runtime successfully configured!"
        
        # Restart docker service to reload /etc/docker/daemon.json
        log_info "Restarting Docker service to register NVIDIA GPU rendering hooks..."
        systemctl restart docker.service 2>/dev/null || true
        log_success "Docker daemon successfully restarted and initialized with GPU support."
    else
        log_error "Failed to configure NVIDIA container runtime."
    fi
else
    log_warn "nvidia-ctk utility was not found. GPU container acceleration deferred."
fi

log_success "Docker Engine & NVIDIA CUDA Stack configured successfully!"
echo -e "\n${YELLOW}💡 Note: Please LOG OUT and LOG IN again to apply 'docker' user group permissions without requiring sudo!${RESET}\n"
