#!/bin/bash
# ==============================================================================
#   cachy-gnome-tweaks - scripts/ai-tools.sh
#   Purpose: Install global Claude Code, shell agent shims & a robust Gemini API CLI
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

log_info "Initiating AI Developer Tools installation for user '${TARGET_USER}'..."

# 1. Install Node.js & npm (Required for Claude Code and JavaScript harnesses)
log_info "Verifying Node.js and npm runtime compatibility..."
pacman -S --needed --noconfirm nodejs npm jq curl || log_warn "Failed to install some Node.js or JSON parse utilities."

# 2. Install Claude Code globally
log_info "Installing Claude Code (@anthropic-ai/claude-code) globally via npm..."
if npm install -g @anthropic-ai/claude-code >>/tmp/cachy-gnome-tweaks.log 2>&1; then
    log_success "Claude Code successfully installed globally!"
else
    log_warn "Standard global npm install hit permission boundaries. Retrying with --unsafe-perm..."
    npm install -g @anthropic-ai/claude-code --unsafe-perm >>/tmp/cachy-gnome-tweaks.log 2>&1 || log_error "Failed to install Claude Code. Check log file."
fi

# 3. Create a state-of-the-art terminal Gemini API CLI (/usr/local/bin/gemini)
log_info "Creating terminal Gemini API CLI helper..."
GEMINI_CLI_PATH="/usr/local/bin/gemini"

cat << 'EOF' > "$GEMINI_CLI_PATH"
#!/bin/bash
# ==============================================================================
#   gemini - Terminal AI Helper
#   Usage: gemini "your query here"
# ==============================================================================
set -eo pipefail

API_KEY_FILE="${HOME}/.config/gemini_api_key"
GEMINI_API_KEY="${GEMINI_API_KEY:-}"

# Load API key from config file if present
if [ -f "$API_KEY_FILE" ] && [ -z "$GEMINI_API_KEY" ]; then
    GEMINI_API_KEY=$(cat "$API_KEY_FILE")
fi

if [ -z "$GEMINI_API_KEY" ]; then
    echo -e "\e[1;33m[!] No Gemini API key detected.\e[0m"
    echo -e "Please get a FREE API key from: https://aistudio.google.com/"
    echo -n "Enter your Gemini API key here: "
    read -r input_key
    if [ -n "$input_key" ]; then
        mkdir -p "$(dirname "$API_KEY_FILE")"
        echo "$input_key" > "$API_KEY_FILE"
        chmod 600 "$API_KEY_FILE"
        GEMINI_API_KEY="$input_key"
        echo -e "\e[1;32m[+] API key saved to ${API_KEY_FILE}!\e[0m\n"
    else
        echo -e "\e[1;31m[ERROR] Gemini API key is required to query the model.\e[0m"
        exit 1
    fi
fi

PROMPT="$*"
if [ -z "$PROMPT" ]; then
    echo -e "Usage: gemini <query text>"
    echo -e "Example: gemini \"Write a python function to fetch status logs\""
    exit 0
fi

echo -e "\e[1;36m[*] Asking Gemini...\e[0m"

# Escape prompt for JSON payload
ESCAPED_PROMPT=$(echo "$PROMPT" | jq -Rsa .)

# Request payload to Gemini 1.5 Flash (highly optimized, low-latency, massive context)
RESPONSE=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -d "{\"contents\": [{\"parts\":[{\"text\": ${ESCAPED_PROMPT}}]}]}" \
  "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=${GEMINI_API_KEY}")

# Check response error status
if echo "$RESPONSE" | jq -e '.error' >/dev/null 2>&1; then
    ERROR_MSG=$(echo "$RESPONSE" | jq -r '.error.message')
    echo -e "\e[1;31m[API ERROR] ${ERROR_MSG}\e[0m"
    exit 1
fi

TEXT_REPLY=$(echo "$RESPONSE" | jq -r '.candidates[0].content.parts[0].text' 2>/dev/null || echo "")

if [ -z "$TEXT_REPLY" ] || [ "$TEXT_REPLY" = "null" ]; then
    echo -e "\e[1;31m[ERROR] Could not parse a valid response from Gemini.\e[0m"
    echo -e "Raw response was: $RESPONSE"
    exit 1
fi

# Print response beautifully
echo -e "\n====================== \e[1;35mGemini Terminal AI\e[0m ======================"
echo -e "$TEXT_REPLY"
echo -e "=================================================================\n"
EOF

chmod +x "$GEMINI_CLI_PATH"
log_success "Gemini Terminal CLI successfully deployed at ${GEMINI_CLI_PATH}"

# 4. Inject convenient shell shims/aliases for AI assistants
log_info "Injecting AI terminal helpers and command aliases..."
BASHRC="${TARGET_HOME}/.bashrc"

if [ -f "$BASHRC" ]; then
    sed -i '/# <<< cachy-gnome-tweaks AI START <<<$/,/# >>> cachy-gnome-tweaks AI END >>>$/d' "$BASHRC"
    cat << 'EOF' >> "$BASHRC"

# <<< cachy-gnome-tweaks AI START <<<
# cachy-gnome-tweaks: AI Developer command shims
alias claude="claude-code"
alias geminia="gemini"
# >>> cachy-gnome-tweaks AI END >>>
EOF
    log_success "Bash aliases registered."
fi

# Fish configuration
FISH_CONF="${TARGET_HOME}/.config/fish/config.fish"
if [ -d "$(dirname "$FISH_CONF")" ] || [ -f "$FISH_CONF" ]; then
    mkdir -p "$(dirname "$FISH_CONF")"
    if [ ! -f "$FISH_CONF" ]; then
        touch "$FISH_CONF"
        chown "${TARGET_USER}:${TARGET_USER}" "$FISH_CONF"
    fi
    sed -i '/# <<< cachy-gnome-tweaks AI START <<<$/,/# >>> cachy-gnome-tweaks AI END >>>$/d' "$FISH_CONF"
    cat << 'EOF' >> "$FISH_CONF"

# <<< cachy-gnome-tweaks AI START <<<
# cachy-gnome-tweaks: AI Developer command shims
alias claude="claude-code"
alias geminia="gemini"
# >>> cachy-gnome-tweaks AI END >>>
EOF
    chown "${TARGET_USER}:${TARGET_USER}" "$FISH_CONF"
    log_success "Fish aliases registered."
fi

log_success "AI Developer Tools applied successfully!"
echo -e "\n${YELLOW}💡 Note: You can now type 'claude' to start Claude Code or 'gemini <query>' to query Gemini 1.5 Flash instantly!${RESET}\n"
