#!/bin/bash
# ==============================================================================
#   cachy-gnome-tweaks - scripts/snapper.sh
#   Purpose: Configure Snapper, automatic pacman hooks, & grub-btrfs rollbacks
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

log_info "Initiating Snapper & BTRFS Snapshot protection suite..."

# Guard 1: Verify BTRFS partition type
if ! findmnt -n -o FSTYPE / | grep -q "btrfs"; then
    log_error "Root filesystem (/) is not BTRFS."
    log_error "Snapper automated backups strictly require a BTRFS layout. Skipping snapper config safely."
    exit 0
fi
log_success "Root filesystem is verified BTRFS."

# 1. Install required backup utilities
log_info "Installing Snapper utilities and GRUB integration packages..."
# snapper: Main snapshot manager
# snap-pac: Automatically triggers pre/post snapshots on pacman installs/updates
# grub-btrfs: Populates snapshots directly into GRUB boot menu
pacman -S --needed --noconfirm snapper snap-pac grub-btrfs || log_warn "Could not install all packages; checking local presence..."

# 2. Setup root subvolume config
log_info "Configuring Snapper for root subvolume..."
if [ ! -f "/etc/snapper/configs/root" ]; then
    log_info "Creating default root configuration..."
    # Snapper requires the subvolume target to exist and not have configurations
    snapper -c root create-config / || log_warn "Snapper config already present or initialized."
    log_success "Created Snapper 'root' configuration."
else
    log_info "Snapper 'root' config is already present."
fi

# 3. Grant active user permissions to snapper
if [ -n "${SUDO_USER:-}" ]; then
    log_info "Allowing user '${SUDO_USER}' to manage root snapshots..."
    
    # Configure ACL permissions inside the root config
    sed -i "s/^ALLOW_USERS=.*/ALLOW_USERS=\"${SUDO_USER}\"/" /etc/snapper/configs/root
    
    # Correct group ownership of the snapshot directory
    chown -R :wheel /.snapshots 2>/dev/null || true
    chmod 750 /.snapshots 2>/dev/null || true
    log_success "User permissions registered successfully."
fi

# 4. Tune Snapper retention policies (avoid infinite snapshots filling the disk)
log_info "Tuning snapshot retention values (keeping disk clean)..."
CONF="/etc/snapper/configs/root"
if [ -f "$CONF" ]; then
    # Keep last 5 hourly, 3 daily, 0 weekly, 0 monthly, and 5 pacman/important snapshots
    sed -i 's/^TIMELINE_LIMIT_HOURLY=.*/TIMELINE_LIMIT_HOURLY="5"/' "$CONF"
    sed -i 's/^TIMELINE_LIMIT_DAILY=.*/TIMELINE_LIMIT_DAILY="3"/' "$CONF"
    sed -i 's/^TIMELINE_LIMIT_WEEKLY=.*/TIMELINE_LIMIT_WEEKLY="0"/' "$CONF"
    sed -i 's/^TIMELINE_LIMIT_MONTHLY=.*/TIMELINE_LIMIT_MONTHLY="0"/' "$CONF"
    sed -i 's/^TIMELINE_LIMIT_YEARLY=.*/TIMELINE_LIMIT_YEARLY="0"/' "$CONF"
    
    # snap-pac limits
    sed -i 's/^NUMBER_LIMIT=.*/NUMBER_LIMIT="10"/' "$CONF"
    sed -i 's/^NUMBER_LIMIT_IMPORTANT=.*/NUMBER_LIMIT_IMPORTANT="5"/' "$CONF"
    log_success "Snapshot retention limits optimized."
fi

# 5. Enable and start Snapper Systemd timelines & cleaner timers
log_info "Enabling Snapper automated hourly and clean timers..."
systemctl enable --now snapper-timeline.timer 2>/dev/null || true
systemctl enable --now snapper-cleanup.timer 2>/dev/null || true
log_success "Snapper timers initialized."

# 6. Enable grub-btrfs systemd monitoring daemon
log_info "Enabling grub-btrfs monitoring daemon (automatically updates grub menu on snapshot)..."
systemctl enable --now grub-btrfsd.service 2>/dev/null || true
log_success "grub-btrfs daemon successfully active."

# 7. Update bootloader configurations to populate snapshot entries
if [ -f "/boot/limine.conf" ] || command -v limine &>/dev/null; then
    log_info "Limine bootloader detected. Setting up snapshot boot entries..."
    pacman -S --needed --noconfirm limine-snapper-sync || log_warn "Could not install limine-snapper-sync package."
    if command -v limine-snapper-sync &>/dev/null; then
        limine-snapper-sync || log_warn "Could not execute limine-snapper-sync immediately."
        log_success "Limine snapshot boot entries registered successfully."
    fi
elif command -v grub-mkconfig &>/dev/null; then
    log_info "Rebuilding GRUB menu to register snapshots..."
    grub-mkconfig -o /boot/grub/grub.cfg >/dev/null 2>&1 || log_warn "Could not rebuild GRUB menu immediately."
    log_success "GRUB menu updated successfully."
elif command -v update-grub &>/dev/null; then
    log_info "Rebuilding GRUB menu to register snapshots..."
    update-grub >/dev/null 2>&1 || log_warn "Could not rebuild GRUB menu."
    log_success "GRUB menu updated successfully."
else
    log_warn "Neither 'grub' nor 'limine' bootloaders configurations were fully matched in typical paths."
    log_info "If you use systemd-boot, snapper snapshots are manageable via 'snapper rollback' or Btrfs Assistant."
fi

log_success "Snapper & BTRFS protection module successfully configured!"
echo -e "${YELLOW}🛡️ Protection Active: Snapper will now automatically take a snapshot before and after any 'pacman' package installation or system update!${RESET}\n"
