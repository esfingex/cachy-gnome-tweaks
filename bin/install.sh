#!/bin/bash
# ==============================================================================
#   cachy-gnome-tweaks - bin/install.sh
#   Purpose: Premium interactive master installer & module selector
# ==============================================================================
set -euo pipefail

# ANSI color codes
CYAN="\e[1;36m"
GREEN="\e[1;32m"
YELLOW="\e[1;33m"
RED="\e[1;31m"
MAGENTA="\e[1;35m"
RESET="\e[0m"

log_info() { echo -e "${CYAN}[*] $1${RESET}"; }
log_success() { echo -e "${GREEN}[+] $1${RESET}"; }
log_warn() { echo -e "${YELLOW}[!] $1${RESET}"; }
log_error() { echo -e "${RED}[ERROR] $1${RESET}" >&2; }

# Setup logging destination
LOG_FILE="/tmp/cachy-gnome-tweaks.log"
echo "=== cachy-gnome-tweaks Installer Log: $(date) ===" > "$LOG_FILE"

# Clean up helper
cleanup() {
    # Terminate background sudo keepalive if running
    if [ -n "${SUDO_PID:-}" ]; then
        kill "$SUDO_PID" 2>/dev/null || true
    fi
}
trap cleanup EXIT

# Get script & project base paths dynamically
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Print premium header
echo -e "${MAGENTA}"
echo -e "  ┌────────────────────────────────────────────────────────┐"
echo -e "  │                                                        │"
echo -e "  │    🏎️   C A C H Y   G N O M E   T W E A K S   🏎️     │"
echo -e "  │       Modular Performance & Dev Stack for CachyOS      │"
echo -e "  │                                                        │"
echo -e "  └────────────────────────────────────────────────────────┘"
echo -e "${RESET}"

log_info "Initializing pre-flight installer checks..."

# Check if pacman is available (Arch-based system validation)
if ! command -v pacman &>/dev/null; then
    log_error "Pacman package manager was not found. This tuning suite is strictly optimized for Arch/CachyOS."
    exit 1
fi

# Request sudo credentials immediately to avoid early timeouts
log_info "Authenticating administrator access (sudo)..."
sudo -v

# Initialize sudo keepalive loop in the background to prevent timeouts
log_info "Starting sudo keepalive daemon..."
while true; do
    sudo -n true
    sleep 60
    kill -0 "$$" || exit
done 2>/dev/null &
SUDO_PID=$!

# Guarantee 'gum' utility is available for premium interactive menus
if ! command -v gum &>/dev/null; then
    log_info "'gum' interactive terminal utility was not found. Installing via pacman..."
    sudo pacman -S --needed --noconfirm gum >> "$LOG_FILE" 2>&1
    log_success "'gum' successfully installed!"
fi

# Present the beautiful selection menu
echo -e "\n${YELLOW}👉 Select the optimization modules you wish to apply:${RESET}"
echo -e "${CYAN}(Use [Space] to toggle, [Enter] to confirm) ${RESET}\n"

CHOICES=$(gum choose --no-limit \
    "⚡ [1] NVIDIA Wayland & Electron HW Acceleration" \
    "🌐 [2] System Latency & Connection sysctl rules" \
    "📂 [3] Linux File Watcher expansions (inotify)" \
    "🛡️  [4] Snapper BTRFS recovery snapshots & pacman hooks" \
    "🛠️  [5] Developer Core (tmux panel splits & mise environment shims)" \
    "📦 [6] Premium Apps Bundle (Vivaldi + GPU VAAPI, Audio stack, BT codecs, OnlyOffice, zip/rar)")

if [ -z "$CHOICES" ]; then
    log_warn "No modules were selected. Exiting installer."
    exit 0
fi

echo -e "\n------------------------------------------------------------"
log_info "Beginning system optimizations..."
echo -e "------------------------------------------------------------\n"

# Execution helpers
run_module() {
    local script_name="$1"
    local title="$2"
    local script_path="${PROJECT_DIR}/scripts/${script_name}"
    
    if [ ! -f "$script_path" ]; then
        log_error "Module script not found: ${script_name}."
        return 1
    fi
    
    chmod +x "$script_path"
    
    log_info "Starting: ${title}"
    
    # Use gum spin to make the CLI experience beautiful
    if gum spin --spinner dot --title "Applying module details..." -- sudo -E bash "$script_path" >> "$LOG_FILE" 2>&1; then
        log_success "Successfully completed: ${title}"
        echo ""
    else
        log_error "Failed module: ${title}."
        log_warn "Check the details in: ${LOG_FILE}"
        echo ""
    fi
}

# Parse selected options and execute them
if echo "$CHOICES" | grep -q "\[1\]"; then
    run_module "nvidia.sh" "NVIDIA Wayland & Electron HW Acceleration"
fi

if echo "$CHOICES" | grep -q "\[2\]"; then
    run_module "network.sh" "System Latency & Network Buffers"
fi

if echo "$CHOICES" | grep -q "\[3\]"; then
    run_module "file-watchers.sh" "Linux File Watcher expansions (inotify)"
fi

if echo "$CHOICES" | grep -q "\[4\]"; then
    run_module "snapper.sh" "Snapper BTRFS Automated Backups"
fi

if echo "$CHOICES" | grep -q "\[5\]"; then
    run_module "dev-tools.sh" "Developer Core Stack (tmux/mise shims)"
fi

if echo "$CHOICES" | grep -q "\[6\]"; then
    run_module "apps-bundle.sh" "Premium Application & Audio Bundle"
fi

echo -e "------------------------------------------------------------"
log_success "Cachy Gnome Tweaks execution run completed!"
log_info "Full detailed installation logs are available at: ${LOG_FILE}"
echo -e "------------------------------------------------------------\n"

echo -e "${GREEN}🎉 All selected modifications have been applied cleanly!${RESET}"
echo -e "${YELLOW}💡 A system restart or logout/login is recommended to apply all variables and configurations.${RESET}\n"
