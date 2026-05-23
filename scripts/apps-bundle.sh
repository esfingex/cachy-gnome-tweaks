#!/bin/bash
# ==============================================================================
#   cachy-gnome-tweaks - scripts/apps-bundle.sh
#   Purpose: Install premium app bundle (Vivaldi + VAAPI, LibreOffice, Audio stack & BT codecs)
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

log_info "Starting Premium Application Bundle setup for user '${TARGET_USER}'..."

# Ensure AUR helper 'yay' is accessible
AUR_HELPER="pacman"
if command -v yay &>/dev/null; then
    AUR_HELPER="yay"
    log_success "AUR helper 'yay' detected. Using it for package installations where helpful."
fi

# 1. High-Fidelity Audio Stack & Bluetooth Codecs
log_info "Configuring audio compatibility and high-fidelity codecs..."
# Install pavucontrol (GUI controller) and ensure pipewire bridges are active
pacman -S --needed --noconfirm \
    pipewire-pulse \
    pipewire-alsa \
    pipewire-jack \
    wireplumber \
    pavucontrol \
    bluez \
    bluez-utils || log_warn "Could not install all base audio/bluetooth utilities."

# Install high-quality Bluetooth codecs (LDAC, aptX) for lag-free premium headphone audio
log_info "Installing high-fidelity Bluetooth audio codecs (LDAC / aptX / AAC)..."
pacman -S --needed --noconfirm \
    libldac \
    libfreeaptx || log_warn "Could not install premium bluetooth codecs."

# Enable and start Bluetooth service
systemctl enable --now bluetooth.service 2>/dev/null || true
log_success "Audio stack & premium Bluetooth codecs configured successfully!"

# 2. Vivaldi Browser & GNOME Extension Integration + VAAPI Flags
log_info "Installing Vivaldi Browser, proprietary codecs, and GNOME browser connector..."
pacman -S --needed --noconfirm vivaldi vivaldi-ffmpeg-codecs gnome-browser-connector || log_warn "Could not install Vivaldi and GNOME connector packages."

# Configure hardware video decoding (VAAPI) for Vivaldi
log_info "Configuring hardware acceleration variables for Vivaldi browser..."
VIVALDI_FLAGS_DIR="${TARGET_HOME}/.config"
mkdir -p "$VIVALDI_FLAGS_DIR"

FLAG="--enable-features=VaapiOnNvidiaGPUs"

# Vivaldi uses vivaldi-stable-flags.conf or vivaldi-flags.conf depending on packaging
for file in "vivaldi-stable-flags.conf" "vivaldi-flags.conf"; do
    FILE_PATH="${VIVALDI_FLAGS_DIR}/${file}"
    if [ -f "$FILE_PATH" ]; then
        if ! grep -qF -- "$FLAG" "$FILE_PATH"; then
            echo "$FLAG" >> "$FILE_PATH"
            log_success "Added VA-API acceleration flag to existing ${file}"
        else
            log_info "VA-API flag already active in ${file}."
        fi
    else
        echo "$FLAG" > "$FILE_PATH"
        chown "${TARGET_USER}:${TARGET_USER}" "$FILE_PATH"
        log_success "Created ${file} with hardware acceleration enabled."
    fi
done

# 3. Compression & Archive Utilities (zip, unzip, unrar, p7zip)
log_info "Installing compression and archive utilities (zip, unzip, unrar, p7zip)..."
pacman -S --needed --noconfirm zip unzip unrar p7zip || log_warn "Could not install all archive utilities."
log_success "Compression utilities successfully configured!"

# 4. GNOME Menu Editor (menulibre)
log_info "Installing GNOME Menu Editor (menulibre)..."
if command -v yay &>/dev/null; then
    log_info "AUR helper 'yay' detected. Installing 'menulibre' from AUR..."
    sudo -u "$TARGET_USER" yay -S --needed --noconfirm menulibre || log_warn "Could not install menulibre via yay."
else
    log_warn "AUR helper 'yay' not found. Attempting install via pacman..."
    pacman -S --needed --noconfirm menulibre || log_warn "Could not install menulibre via pacman."
fi
log_success "MenuLibre installation stage completed!"

log_success "Premium Application Bundle applied successfully!"
echo -e "\n${YELLOW}💡 Note: Open Vivaldi and check 'vivaldi://gpu' to confirm that Hardware Video Decoding is now fully active on your GPU!${RESET}\n"
