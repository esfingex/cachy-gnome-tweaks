#!/bin/bash
# ==============================================================================
#   cachy-gnome-tweaks - scripts/dev-tools.sh
#   Purpose: Install yay, tmux, and mise runtime activation shims safely
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

log_info "Initiating Developer Stack setup for user '${TARGET_USER}'..."

# 1. Install packages via pacman (highly optimized Arch packages)
log_info "Installing tmux and mise via pacman..."
pacman -S --needed --noconfirm tmux mise || log_warn "Could not install all developer packages through pacman immediately."

# 2. Check and bootstrap yay helper if missing
log_info "Verifying AUR helper (yay)..."
if ! command -v yay &>/dev/null; then
    log_info "yay helper not found in PATH. Attempting to install it..."
    pacman -S --needed --noconfirm yay || log_warn "Could not bootstrap 'yay' using pacman."
else
    log_success "yay is present."
fi

# 3. Configure tmux
log_info "Configuring tmux workspace layout..."
TMUX_SRC="/home/athena/Github/cachy-gnome-tweaks/config/tmux.conf"
TMUX_DST="${TARGET_HOME}/.tmux.conf"

if [ -f "$TMUX_SRC" ]; then
    cp "$TMUX_SRC" "$TMUX_DST"
    chown "${TARGET_USER}:${TARGET_USER}" "$TMUX_DST"
    log_success "Copied premium tmux profile to ${TMUX_DST}"
else
    log_warn "Source tmux.conf not found at ${TMUX_SRC}."
fi

# 4. Inject shell activation shims for mise
log_info "Registering shell activation scripts for mise..."
CONFIG_DIR="${TARGET_HOME}/.config"

# --- BASH CONFIGURATION ---
BASHRC="${TARGET_HOME}/.bashrc"
if [ -f "$BASHRC" ]; then
    log_info "Injecting environment hooks into ${BASHRC}..."
    
    # Remove older hooks or blocks safely
    sed -i '/# <<< cachy-gnome-tweaks START <<<$/,/# >>> cachy-gnome-tweaks END >>>$/d' "$BASHRC"
    sed -i '/# cachy-gnome-tweaks/d' "$BASHRC"
    sed -i '/mise activate bash/d' "$BASHRC"
    
    # Append fresh shims in a clean block
    cat << 'EOF' >> "$BASHRC"

# <<< cachy-gnome-tweaks START <<<
# cachy-gnome-tweaks: Developer environment shims
if command -v mise &>/dev/null; then
    eval "$(mise activate bash)"
fi
# >>> cachy-gnome-tweaks END >>>
EOF
    log_success "Bash configurations injected."
else
    log_info "No .bashrc file detected for '${TARGET_USER}'."
fi

# --- FISH CONFIGURATION ---
FISH_CONF="${CONFIG_DIR}/fish/config.fish"
if [ -d "${CONFIG_DIR}/fish" ] || [ -f "$FISH_CONF" ]; then
    log_info "Injecting environment hooks into ${FISH_CONF}..."
    mkdir -p "$(dirname "$FISH_CONF")"
    chown -R "${TARGET_USER}:${TARGET_USER}" "${CONFIG_DIR}/fish"
    
    # Touch file if not exists
    if [ ! -f "$FISH_CONF" ]; then
        touch "$FISH_CONF"
        chown "${TARGET_USER}:${TARGET_USER}" "$FISH_CONF"
    fi
    
    # Clean previous blocks safely
    sed -i '/# <<< cachy-gnome-tweaks START <<<$/,/# >>> cachy-gnome-tweaks END >>>$/d' "$FISH_CONF"
    sed -i '/# cachy-gnome-tweaks/d' "$FISH_CONF"
    sed -i '/mise activate fish/d' "$FISH_CONF"
    
    # Append fresh fish shims in a clean block
    cat << 'EOF' >> "$FISH_CONF"

# <<< cachy-gnome-tweaks START <<<
# cachy-gnome-tweaks: Developer environment shims
if status is-interactive
    if type -q mise
        mise activate fish | source
    end
end
# >>> cachy-gnome-tweaks END >>>
EOF
    log_success "Fish configurations injected."
else
    log_info "Fish shell layout directory not active."
fi

log_success "Developer stack applied successfully!"
