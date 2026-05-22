#!/bin/bash
# ==============================================================================
#   cachy-gnome-tweaks - scripts/kvm-qemu.sh
#   Purpose: Install and configure high-performance KVM & QEMU Virtualization Stack
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

log_info "Starting High-Performance KVM/QEMU Virtualization stack installation..."

# 1. Install QEMU, Virt-Manager, Dnsmasq, and Firewall utilities
log_info "Installing QEMU full package group, Virt-Manager GUI, and bridge utilities..."
pacman -S --needed --noconfirm \
    qemu-full \
    virt-manager \
    virt-viewer \
    dnsmasq \
    vde2 \
    bridge-utils \
    openbsd-netcat \
    iptables-nft \
    libguestfs || log_warn "Could not install all virtualization libraries through pacman."

# 2. Configure systemd services for Libvirt
log_info "Activating and enabling virtualization daemons..."
systemctl enable --now libvirtd.service 2>/dev/null || true
systemctl enable --now virtlogd.service 2>/dev/null || true

# 3. Add current user to libvirt group for non-sudo workspace permissions
log_info "Registering user '${TARGET_USER}' in 'libvirt' group..."
if getent group libvirt >/dev/null; then
    usermod -aG libvirt "$TARGET_USER"
    log_success "Added ${TARGET_USER} to libvirt group."
else
    groupadd libvirt 2>/dev/null || true
    usermod -aG libvirt "$TARGET_USER"
    log_success "Created libvirt group and registered ${TARGET_USER}."
fi

# 4. Activate and autostart Virt-Manager default NAT bridge network
log_info "Configuring default virtual bridge network interface..."
if command -v virsh &>/dev/null; then
    # Sometimes it takes a split second for libvirtd to socket bind
    sleep 1
    
    # Try to define, start, and autostart the default NAT network
    if virsh net-info default >/dev/null 2>&1; then
        log_info "Default network already defined."
    else
        log_info "Defining default network bridge..."
        # If not active or defined, search for standard template inside /etc/libvirt
        if [ -f "/etc/libvirt/qemu/networks/default.xml" ]; then
            virsh net-define /etc/libvirt/qemu/networks/default.xml 2>/dev/null || true
        fi
    fi

    # Start and autostart it
    virsh net-start default 2>/dev/null || log_warn "Default NAT network could not be started automatically. This is common if kernel modules are not reloaded yet."
    virsh net-autostart default 2>/dev/null || true
    log_success "Virtual NAT networking bridges activated!"
else
    log_warn "virsh utility was not found. Networking setup deferred."
fi

log_success "KVM/QEMU Virtualization Stack configured successfully!"
echo -e "\n${YELLOW}💡 Note: Please LOG OUT and LOG IN again to apply 'libvirt' user group permissions! Open 'Virtual Machine Manager' to start creating your premium VMs.${RESET}\n"
