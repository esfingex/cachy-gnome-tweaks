#!/bin/bash
# ==============================================================================
#   cachy-gnome-tweaks - scripts/nvidia.sh
#   Purpose: NVIDIA Wayland & Electron hardware acceleration tuning module
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

log_info "Starting NVIDIA & Wayland Hardware Acceleration setup..."

# Check if NVIDIA hardware is present
if ! lspci | grep -qi nvidia; then
    log_warn "No NVIDIA hardware detected in lspci. Proceeding anyway by user request..."
else
    log_success "NVIDIA hardware detected."
fi

# Target file for environment variables
ENV_FILE="/etc/environment"
backup_created=false

# Helper to inject variables idempotently
inject_env() {
    local key="$1"
    local val="$2"
    
    # Create backup of /etc/environment once
    if [ "$backup_created" = false ]; then
        cp "$ENV_FILE" "${ENV_FILE}.backup-tweaks"
        backup_created=true
        log_info "Created backup of ${ENV_FILE} at ${ENV_FILE}.backup-tweaks"
    fi

    if grep -q "^${key}=" "$ENV_FILE"; then
        # Update existing variable safely
        sed -i "s|^${key}=.*|${key}=${val}|" "$ENV_FILE"
        log_info "Updated: ${key}=${val}"
    else
        # Append new variable
        echo "${key}=${val}" >> "$ENV_FILE"
        log_success "Added: ${key}=${val}"
    fi
}

# Apply optimal variables for flawless Wayland/Electron GPU rendering
inject_env "__GLX_VENDOR_LIBRARY_NAME" "nvidia"
inject_env "GBM_BACKEND" "nvidia-drm"
inject_env "NVD_BACKEND" "direct"
inject_env "ELECTRON_OZONE_PLATFORM_HINT" "auto"

log_success "Environment variables successfully configured in ${ENV_FILE}."

# Setup Chromium / Chrome hardware video decoding support
log_info "Configuring Chromium / Chrome hardware acceleration shims..."
CHROME_FLAGS_FILE="/home/${SUDO_USER:-$USER}/.config/chromium-flags.conf"
CHROME_FLAGS_DIR=$(dirname "$CHROME_FLAGS_FILE")

mkdir -p "$CHROME_FLAGS_DIR"
chown -R "${SUDO_USER:-$USER}:${SUDO_USER:-$USER}" "$CHROME_FLAGS_DIR"

FLAG="--enable-features=VaapiOnNvidiaGPUs"
if [ -f "$CHROME_FLAGS_FILE" ]; then
    if ! grep -qF "$FLAG" "$CHROME_FLAGS_FILE"; then
        echo "$FLAG" >> "$CHROME_FLAGS_FILE" # Append
        log_success "Added Vaapi flag to existing chromium-flags.conf"
    else
        log_info "Chromium VA-API flags already configured."
    fi
else
    echo "$FLAG" > "$CHROME_FLAGS_FILE"
    chown "${SUDO_USER:-$USER}:${SUDO_USER:-$USER}" "$CHROME_FLAGS_FILE"
    log_success "Created chromium-flags.conf with VA-API enabled."
fi

log_success "NVIDIA & Wayland acceleration module applied successfully!"
echo -e "\n${YELLOW}💡 Note: Please restart your session (log out and log in) to apply environment changes.${RESET}\n"
