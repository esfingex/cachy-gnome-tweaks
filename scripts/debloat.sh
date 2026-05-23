#!/bin/bash
# ==============================================================================
#   cachy-gnome-tweaks - scripts/debloat.sh
#   Purpose: Interactive bloatware remover to purge unused packages safely
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

log_info "Initiating Bloatware Remover utility..."

# Verify 'gum' utility is available
if ! command -v gum &>/dev/null; then
    log_info "Installing 'gum' terminal selector..."
    pacman -S --needed --noconfirm gum >>/dev/null 2>&1
fi

# Define candidates with descriptive names and actual package names
declare -A APP_PKG_MAP
APP_PKG_MAP["🧹 Alacritty Terminal Emulator"]="alacritty"
APP_PKG_MAP["🌐 GNOME Web (Epiphany Browser)"]="epiphany"
APP_PKG_MAP["🧭 GNOME Tour (System Intro)"]="gnome-tour"
APP_PKG_MAP["📞 GNOME Contacts"]="gnome-contacts"
APP_PKG_MAP["🗺️ GNOME Maps"]="gnome-maps"
APP_PKG_MAP["☁️ GNOME Weather"]="gnome-weather"
APP_PKG_MAP["🎵 GNOME Music"]="gnome-music"
APP_PKG_MAP["📥 lftp (Console FTP Client)"]="lftp"

# List choices dynamically, only showing packages that are actually installed
INSTALLED_CHOICES=()
for app in "${!APP_PKG_MAP[@]}"; do
    pkg="${APP_PKG_MAP[$app]}"
    if pacman -Q "$pkg" &>/dev/null; then
        INSTALLED_CHOICES+=("$app")
    fi
done

if [ ${#INSTALLED_CHOICES[@]} -eq 0 ]; then
    log_success "Excellent! No standard bloatware packages were found installed on this system."
    exit 0
fi

echo -e "\n${YELLOW}👉 Select the applications you wish to UNINSTALL (debloat):${RESET}"
echo -e "${CYAN}(Use [Space] to toggle, [Enter] to confirm) ${RESET}\n"

# Run gum select
CHOICES=$(printf "%s\n" "${INSTALLED_CHOICES[@]}" | gum choose --no-limit \
    --header="⚠️  ¡IMPORTANTE! Selecciona con [ESPACIO] las aplicaciones a ELIMINAR, luego [ENTER] para confirmar:")

if [ -z "$CHOICES" ]; then
    log_warn "No packages were selected for removal. Exiting debloat module."
    exit 0
fi

# Map selected choices back to package names
PKGS_TO_REMOVE=()
echo -e "\nSelected applications for removal:"
while IFS= read -r choice; do
    if [ -n "$choice" ]; then
        pkg="${APP_PKG_MAP[$choice]}"
        PKGS_TO_REMOVE+=("$pkg")
        echo -e "  - ${RED}${pkg}${RESET} (${choice})"
    fi
done <<< "$CHOICES"

# Prompt for final confirmation
echo -e "\n${YELLOW}⚠️  WARNING: This will permanently remove the selected packages along with their configurations.${RESET}"
if gum confirm "¿Estás seguro de que deseas desinstalar estas aplicaciones?"; then
    log_info "Proceeding with removal of: ${PKGS_TO_REMOVE[*]}"
    
    # Run pacman -Rns on selected packages
    if pacman -Rns --noconfirm "${PKGS_TO_REMOVE[@]}"; then
        log_success "Successfully removed selected bloatware packages!"
    else
        log_error "Some packages could not be removed cleanly. Please check pacman log."
    fi
else
    log_warn "Debloat operation cancelled by the user."
fi
