#!/bin/bash
# ==============================================================================
#   cachy-gnome-tweaks - scripts/antigravity.sh
#   Purpose: Dedicated and modular installer for Antigravity IDE Workspace Launcher
#            Automatically downloads, mounts, and updates the premium standalone release.
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

# ==============================================================================
# CONFIGURATION & AUTOMATED UPDATE CHECKER
# ==============================================================================
FALLBACK_URL="https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/2.0.3-6242596486512640/linux-x64/Antigravity%20IDE.tar.gz"
DOWNLOAD_URL=""
INSTALL_DIR="/opt/antigravity-ide"
TEMP_TAR="/tmp/Antigravity_IDE.tar.gz"

log_info "Checking for the latest Antigravity IDE release from official portal..."

# Attempt to resolve the download URL dynamically from antigravity.google website
if JS_FILE=$(curl -sL --compressed "https://antigravity.google/download" 2>/dev/null | grep -oE 'main-[A-Za-z0-9]+\.js' | head -n 1); then
    if [ -n "$JS_FILE" ]; then
        log_info "Found active script bundle: ${JS_FILE}"
        if RESOLVED_URL=$(curl -sL --compressed "https://antigravity.google/${JS_FILE}" 2>/dev/null | grep -oE "https://[^\"]*linux-x64/Antigravity%20IDE.tar.gz" | head -n 1); then
            if [ -n "$RESOLVED_URL" ]; then
                DOWNLOAD_URL="$RESOLVED_URL"
                log_success "Successfully resolved latest release URL: ${DOWNLOAD_URL}"
            fi
        fi
    fi
fi

if [ -z "$DOWNLOAD_URL" ]; then
    log_warn "Could not resolve latest release URL dynamically. Falling back to default: ${FALLBACK_URL}"
    DOWNLOAD_URL="$FALLBACK_URL"
fi

log_info "Deploying premium Antigravity IDE Launcher & workspace integration..."

# 1. Download official standalone Antigravity IDE release
log_info "Downloading official premium Antigravity IDE standalone tarball..."
log_info "Source: ${DOWNLOAD_URL}"

# Ensure wget or curl is present
if command -v curl &>/dev/null; then
    curl -L -o "$TEMP_TAR" "$DOWNLOAD_URL"
elif command -v wget &>/dev/null; then
    wget -O "$TEMP_TAR" "$DOWNLOAD_URL"
else
    log_error "Neither curl nor wget was found in your system PATH. Cannot download the installer."
    exit 1
fi

log_success "Download complete!"

# 2. Extract and mount the IDE inside /opt/antigravity-ide
log_info "Preparing installation directory at ${INSTALL_DIR}..."
# Clean any previous installation to support seamless upgrades
rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"

log_info "Extracting files to ${INSTALL_DIR}..."
# Extract stripping the root folder "Antigravity IDE/" inside the tarball to make it flat
tar -xzf "$TEMP_TAR" -C "$INSTALL_DIR" --strip-components=1

# Ensure executable permissions on the main binary
chmod +x "${INSTALL_DIR}/antigravity-ide"

# Clean up temp file
rm -f "$TEMP_TAR"
log_success "Antigravity IDE successfully mounted at ${INSTALL_DIR}!"

# 3. Create the executable launcher /usr/local/bin/antigravity
LAUNCHER_PATH="/usr/local/bin/antigravity"
log_info "Creating global launcher command at ${LAUNCHER_PATH}..."

cat << 'EOF' > "$LAUNCHER_PATH"
#!/bin/bash
# ==============================================================================
#   antigravity - Premium AI-Integrated Developer Terminal & VS Code Launcher
# ==============================================================================
set -eo pipefail

CYAN="\e[1;36m"
MAGENTA="\e[1;35m"
RESET="\e[0m"

clear
echo -e "${CYAN}"
echo -e "   ┌────────────────────────────────────────────────────────┐"
echo -e "   │                                                        │"
echo -e "   │          🛸   A N T I G R A V I T Y   I D E   🛸       │"
echo -e "   │         High-Performance Agentic Workspace Terminal    │"
echo -e "   │                                                        │"
echo -e "   └────────────────────────────────────────────────────────┘"
echo -e "${RESET}"

TARGET_DIR="${1:-${PWD}}"
echo -e "${CYAN}[*] Starting workspace runtime in: ${TARGET_DIR}...${RESET}"

# Launch premium Antigravity IDE standalone instead of standard code
if [ -x "/opt/antigravity-ide/antigravity-ide" ]; then
    /opt/antigravity-ide/antigravity-ide "$TARGET_DIR" &
    echo -e "${MAGENTA}[+] Antigravity IDE successfully hooked and spawned in the background.${RESET}"
else
    echo -e "\e[1;31m[ERROR] Antigravity IDE executable was not found at /opt/antigravity-ide/antigravity-ide\e[0m"
    echo -e "Please run: sudo ./scripts/antigravity.sh to reinstall."
    exit 1
fi

# Spawns a premium developer tmux shell or basic shell
if command -v tmux &>/dev/null; then
    echo -e "${CYAN}[*] Attaching persistent developer tmux workbench...${RESET}\n"
    sleep 0.5
    tmux new-session -A -s "antigravity" -c "$TARGET_DIR"
else
    echo -e "${CYAN}[*] TMUX not found. Deploying default agentic bash shell...${RESET}\n"
    bash
fi
EOF

chmod +x "$LAUNCHER_PATH"

# 4. Create a beautiful .desktop shortcut for GNOME menu
SHORTCUT_DIR="${TARGET_HOME}/.local/share/applications"
mkdir -p "$SHORTCUT_DIR"
SHORTCUT_PATH="${SHORTCUT_DIR}/antigravity.desktop"

log_info "Creating GNOME desktop shortcut entry..."
cat << EOF > "$SHORTCUT_PATH"
[Desktop Entry]
Name=Antigravity IDE
Comment=High-Performance Agentic Workspace Terminal
Exec=/usr/local/bin/antigravity
Icon=utilities-terminal
Terminal=true
Type=Application
Categories=Development;IDE;TerminalEmulator;
StartupNotify=true
EOF

chown "${TARGET_USER}:${TARGET_USER}" "$SHORTCUT_PATH"
chmod +x "$SHORTCUT_PATH"

log_success "Antigravity IDE Launcher & workspace integration successfully configured!"
echo -e "${YELLOW}💡 Note: You can now type 'antigravity' in terminal or launch 'Antigravity IDE' directly from your GNOME Applications Overview!${RESET}"
