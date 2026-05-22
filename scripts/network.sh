#!/bin/bash
# ==============================================================================
#   cachy-gnome-tweaks - scripts/network.sh
#   Purpose: Network latency, sysctl MTU probing, & iwd backend config module
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

log_info "Applying Network and Connection stability tweaks..."

# 1. MTU Probing configuration for robust TCP connections & SSH stability
SYSCTL_FILE="/etc/sysctl.d/99-cachy-gnome-tweaks.conf"
log_info "Injecting TCP MTU probing sysctl rule into ${SYSCTL_FILE}..."

mkdir -p "$(dirname "$SYSCTL_FILE")"

# Remove existing key if already there to avoid duplicates
if [ -f "$SYSCTL_FILE" ]; then
    sed -i '/net.ipv4.tcp_mtu_probing/d' "$SYSCTL_FILE"
fi

echo "net.ipv4.tcp_mtu_probing=1" >> "$SYSCTL_FILE"
sysctl --system >/dev/null 2>&1 || log_warn "Could not hot-reload sysctl configurations immediately; they will apply on next boot."
log_success "TCP MTU probing enabled successfully."

# 2. Prevent systemd-networkd-wait-online from stalling boot
log_info "Optimizing systemd network startup timeouts..."
systemctl disable systemd-networkd-wait-online.service 2>/dev/null || true
systemctl mask systemd-networkd-wait-online.service 2>/dev/null || true
log_success "Network wait-online timeout masked cleanly."

# 3. Configure NetworkManager to leverage iwd backend (optional but highly recommended for fast WiFi roaming)
log_info "Checking WiFi network backend configuration..."
if command -v iwd &>/dev/null; then
    log_info "iwd package detected. Configuring NetworkManager to use iwd backend..."
    
    systemctl enable iwd.service 2>/dev/null || true
    systemctl disable wpa_supplicant.service 2>/dev/null || true
    
    NM_CONF="/etc/NetworkManager/NetworkManager.conf"
    if [ -f "$NM_CONF" ]; then
        if ! grep -q "wifi.backend=iwd" "$NM_CONF"; then
            # Injecting safely
            if grep -q "\[device\]" "$NM_CONF"; then
                # Device section exists, insert underneath it
                sed -i '/\[device\]/a wifi.backend=iwd' "$NM_CONF"
            else
                # Append section and value
                printf "\n[device]\nwifi.backend=iwd\n" >> "$NM_CONF"
            fi
            log_success "NetworkManager wifi.backend set to 'iwd'."
        else
            log_info "NetworkManager is already configured to use 'iwd' backend."
        fi
    else
        mkdir -p "$(dirname "$NM_CONF")"
        printf "[device]\nwifi.backend=iwd\n" > "$NM_CONF"
        log_success "Created NetworkManager.conf with 'iwd' wifi backend."
    fi
else
    log_warn "'iwd' package is not installed. Skipping wifi backend switch to preserve default backend."
fi

log_success "Network optimization module applied successfully!"
