#!/bin/bash
# ==============================================================================
#   cachy-gnome-tweaks - scripts/file-watchers.sh
#   Purpose: Expand Linux inotify file-watcher limits for heavy IDEs/compilers
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

log_info "Applying Linux inotify File-Watcher expansions..."

WATCHERS_FILE="/etc/sysctl.d/90-cachy-gnome-file-watchers.conf"
log_info "Writing sysctl values into ${WATCHERS_FILE}..."

mkdir -p "$(dirname "$WATCHERS_FILE")"

# Safe, clean creation of the configuration file
tee "$WATCHERS_FILE" > /dev/null << EOF
# cachy-gnome-tweaks: Expand file-watching capacity to support heavy dev IDEs (VSCode/Neovim) and hot-reload engines (Vite/Webpack)
fs.inotify.max_user_watches=524288
fs.inotify.max_user_instances=512
EOF

log_success "File-watcher configuration file written."

# Hot-reload the sysctl configurations cleanly
log_info "Applying new sysctl variables to live kernel..."
if sysctl --system >/dev/null 2>&1; then
    log_success "Kernel parameters applied successfully!"
    log_info "Current Max User Watches: $(cat /proc/sys/fs/inotify/max_user_watches)"
    log_info "Current Max User Instances: $(cat /proc/sys/fs/inotify/max_user_instances)"
else
    log_warn "Could not live reload sysctl parameters. They will be loaded automatically on next boot."
fi

log_success "File-watcher expansion module completed successfully!"
