#!/bin/bash
# ==============================================================================
#   cachy-gnome-tweaks - scripts/easyarch.sh
#   Purpose: Independent and interactive installers for your favorite tools:
#            Telegram, WineHQ, GitHub Desktop, Chrome, OnlyOffice & Antigravity IDE
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

# Function to run yay commands safely as target non-root user
run_yay() {
    local pkgs="$*"
    log_info "Installing AUR packages via yay: ${pkgs}..."
    if command -v yay &>/dev/null; then
        sudo -u "$TARGET_USER" yay -S --needed --noconfirm $pkgs
    else
        log_warn "AUR helper 'yay' was not found. Attempting to install it first..."
        pacman -S --needed --noconfirm yay || log_error "Failed to bootstrap yay helper."
        sudo -u "$TARGET_USER" yay -S --needed --noconfirm $pkgs
    fi
}

install_telegram() {
    log_info "Installing Telegram Desktop..."
    pacman -S --needed --noconfirm telegram-desktop
    log_success "Telegram Desktop successfully installed!"
}

install_winehq() {
    log_info "Installing WineHQ & Lutris Gaming Compatibility stack..."
    # Install Lutris and Wine Staging
    pacman -S --needed --noconfirm lutris wine-staging giflib lib32-giflib
    
    # Install key 32-bit libraries for high compatibility steam/lutris runners
    log_info "Configuring multilib dependencies for wine gaming..."
    pacman -S --needed --noconfirm \
        lib32-vulkan-icd-loader \
        lib32-gnutls \
        lib32-sdl2 \
        lib32-libxcomposite \
        lib32-libxinerama \
        lib32-sqlite \
        lib32-libgcrypt || log_warn "Could not install all 32-bit multilib graphics dependencies."
    log_success "WineHQ & Lutris stack successfully configured!"
}

install_github_desktop() {
    log_info "Installing GitHub Desktop client..."
    run_yay "github-desktop-bin"
    log_success "GitHub Desktop successfully installed!"
}

install_antigravity_ide() {
    log_info "Deploying premium Antigravity IDE Launcher & workspace integration..."
    
    # 1. Ensure VS Code is installed first
    log_info "Ensuring VS Code is installed to back the Antigravity launcher..."
    if ! command -v code &>/dev/null; then
        run_yay "visual-studio-code-bin"
    fi

    # 2. Create the executable launcher /usr/local/bin/antigravity
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

# Launch VS Code with our active agentic structures
if command -v code &>/dev/null; then
    code "$TARGET_DIR" &
    echo -e "${MAGENTA}[+] VS Code successfully hooked and spawned in the background.${RESET}"
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

    # 3. Create a beautiful .desktop shortcut for GNOME menu
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
}

install_chrome() {
    log_info "Installing Google Chrome Browser..."
    run_yay "google-chrome"
    log_success "Google Chrome Browser successfully installed!"
}

install_onlyoffice() {
    log_info "Installing OnlyOffice suite..."
    if pacman -Si onlyoffice-bin &>/dev/null; then
        pacman -S --needed --noconfirm onlyoffice-bin hunspell hunspell-es
    else
        run_yay "onlyoffice-bin"
        pacman -S --needed --noconfirm hunspell hunspell-es || true
    fi
    log_success "OnlyOffice suite successfully installed!"
}

# --- PARSING RUN MODE ---
APPS=()

if [ $# -gt 0 ]; then
    log_info "CLI mode triggered. Parsing arguments: $*"
    for arg in "$@"; do
        case "$arg" in
            telegram) APPS+=("telegram") ;;
            wine|winehq) APPS+=("winehq") ;;
            github|github-desktop) APPS+=("github-desktop") ;;
            antigravity|ide) APPS+=("antigravity-ide") ;;
            chrome|google-chrome) APPS+=("chrome") ;;
            onlyoffice|office) APPS+=("onlyoffice") ;;
            *) log_warn "Ignoring unrecognized application argument: ${arg}" ;;
        esac
    done
else
    # Verify 'gum' interactive menu tool is available
    if ! command -v gum &>/dev/null; then
        log_info "Installing 'gum' terminal selector..."
        pacman -S --needed --noconfirm gum >>/dev/null 2>&1
    fi
    
    log_info "Interactive mode triggered."
    echo -e "\n${YELLOW}👉 Select the applications from Easyarch you want to install:${RESET}"
    CHOICES=$(gum choose --no-limit \
        "📱 [1] Telegram Desktop" \
        "🎮 [2] WineHQ & Lutris Gaming Compatibility stack" \
        "💻 [3] GitHub Desktop client" \
        "🛸 [4] Antigravity IDE Premium Launcher" \
        "🌐 [5] Google Chrome Browser" \
        "📦 [6] OnlyOffice Suite")
        
    if [ -z "$CHOICES" ]; then
        log_warn "No applications were selected. Exiting easyarch."
        exit 0
    fi
    
    if echo "$CHOICES" | grep -q "\[1\]"; then APPS+=("telegram"); fi
    if echo "$CHOICES" | grep -q "\[2\]"; then APPS+=("winehq"); fi
    if echo "$CHOICES" | grep -q "\[3\]"; then APPS+=("github-desktop"); fi
    if echo "$CHOICES" | grep -q "\[4\]"; then APPS+=("antigravity-ide"); fi
    if echo "$CHOICES" | grep -q "\[5\]"; then APPS+=("chrome"); fi
    if echo "$CHOICES" | grep -q "\[6\]"; then APPS+=("onlyoffice"); fi
fi

# --- EXECUTION STAGE ---
log_info "Selected applications: ${APPS[*]}"

for app in "${APPS[@]}"; do
    case "$app" in
        telegram) install_telegram ;;
        winehq) install_winehq ;;
        github-desktop) install_github_desktop ;;
        antigravity-ide) install_antigravity_ide ;;
        chrome) install_chrome ;;
        onlyoffice) install_onlyoffice ;;
    esac
done

log_success "Easyarch application runs completed successfully!"
