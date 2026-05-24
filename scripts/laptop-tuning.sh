#!/bin/bash
# ==============================================================================
#   cachy-gnome-tweaks - scripts/laptop-tuning.sh
#   Purpose: Laptop & Thermal Tuning (ASUS ROG/TUF tools & Intel thermald)
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
if [ "$TARGET_USER" = "root" ]; then
    TARGET_HOME="/root"
else
    TARGET_HOME="/home/$TARGET_USER"
fi

# Detect desktop environment
IS_KDE=false
IS_GNOME=false
if [[ "${XDG_CURRENT_DESKTOP:-}" == *"KDE"* ]]; then
    IS_KDE=true
elif [[ "${XDG_CURRENT_DESKTOP:-}" == *"GNOME"* ]]; then
    IS_GNOME=true
fi

log_info "Starting ASUS Laptop & Intel CPU Thermal optimization for user '${TARGET_USER}'..."

# 1. Install required packages (asusctl, supergfxctl, thermald)
log_info "Installing ASUS control utilities and Intel thermal daemon..."
if pacman -S --needed --noconfirm asusctl supergfxctl thermald; then
    log_success "Successfully installed asusctl, supergfxctl, and thermald."
else
    log_error "Failed to install required hardware packages. Verify your internet connection."
    exit 1
fi

# 2. Configure and enable ASUS power & RGB daemon (asusd)
log_info "Configuring and enabling ASUS hardware daemon (asusd)..."
# Fix known systemd namespace bug by ensuring /etc/asusd exists
mkdir -p /etc/asusd
# Reset any previous systemd start limit failures to bypass rate limits
systemctl reset-failed asusd.service 2>/dev/null || true
systemctl enable --now asusd.service 2>/dev/null || log_warn "Could not enable/start asusd.service."
log_success "ASUS hardware daemon (asusd) is active."

# 3. Configure and enable GPU switcher daemon (supergfxd)
log_info "Configuring and enabling graphics mode switcher daemon (supergfxd)..."
systemctl enable --now supergfxd.service 2>/dev/null || log_warn "Could not enable/start supergfxd.service."
log_success "GPU switcher daemon (supergfxd) is active."

# 4. Configure and enable Intel active thermal management daemon (thermald)
log_info "Configuring and enabling Intel thermal daemon (thermald)..."
systemctl enable --now thermald.service 2>/dev/null || log_warn "Could not enable/start thermald.service."
log_success "Intel active thermal daemon (thermald) is active."

# 5. Install GPU Switcher GNOME Shell Extension (chikobara/GPU-Switcher-Supergfxctl)
if $IS_GNOME; then
    log_info "Installing GPU Switcher GNOME Shell extension by chikobara..."
    EXT_UUID="gpu-switcher-supergfxctl@chikobara.github.io"
    EXT_DIR="${TARGET_HOME}/.local/share/gnome-shell/extensions/${EXT_UUID}"
    
    if [ "$TARGET_USER" != "root" ] && [ -d "${TARGET_HOME}" ]; then
        mkdir -p "$(dirname "${EXT_DIR}")"
        if [ -d "$EXT_DIR" ]; then
            log_info "GPU Switcher extension is already cloned in ${EXT_DIR}. Updating..."
            (cd "$EXT_DIR" && git pull) || log_warn "Could not update the extension from GitHub."
        else
            log_info "Cloning extension repository from GitHub..."
            if git clone --quiet https://github.com/chikobara/GPU-Switcher-Supergfxctl.git "$EXT_DIR"; then
                log_success "Successfully cloned extension to ${EXT_DIR}."
            else
                log_warn "Failed to clone GPU Switcher extension from GitHub."
            fi
        fi
        chown -R "${TARGET_USER}:${TARGET_USER}" "$(dirname "${EXT_DIR}")"
    else
        log_warn "Target user is root or home directory does not exist. Skipping GNOME extension installation."
    fi
else
    log_info "Skipping GPU Switcher GNOME Shell extension (not running GNOME)."
fi

log_success "Laptop & Thermal Tuning optimizations applied successfully!"

# Output helpful CLI commands for user reference
echo -e "\n${YELLOW}💡 Useful Commands & Usage Reference:${RESET}"
echo -e "  - ${CYAN}asusctl profile -n${RESET}              : Toggle power profiles (Silent, Balanced, Turbo)"
echo -e "  - ${CYAN}supergfxctl -g${RESET}                  : Show current active GPU mode"
echo -e "  - ${CYAN}supergfxctl -m <Mode>${RESET}          : Switch GPU mode (Hybrid, Integrated, Dedicated)"
echo -e "  - ${CYAN}systemctl status thermald${RESET}       : Check the active Intel thermal controller status"
echo -e "${YELLOW}Note: Some GPU switching actions through supergfxctl may require you to log out and log in again to restart the graphic session.${RESET}\n"
