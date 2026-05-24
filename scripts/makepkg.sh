#!/bin/bash
# ==============================================================================
#   cachy-gnome-tweaks - scripts/makepkg.sh
#   Purpose: Arch & CachyOS makepkg Native Compiler & RAM-disk optimization
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

log_info "Starting Arch & CachyOS makepkg compiler optimization..."

MAKEPKG_CONF="/etc/makepkg.conf"
BACKUP_FILE="${MAKEPKG_CONF}.backup-tweaks"

if [ ! -f "$MAKEPKG_CONF" ]; then
    log_error "Configuration file not found at ${MAKEPKG_CONF}. Are you running Arch/CachyOS?"
    exit 1
fi

# 1. Create a safe backup if it doesn't already exist
if [ ! -f "$BACKUP_FILE" ]; then
    cp "$MAKEPKG_CONF" "$BACKUP_FILE"
    log_success "Created backup of ${MAKEPKG_CONF} at ${BACKUP_FILE}"
else
    log_info "Backup already exists at ${BACKUP_FILE}"
fi

# Ensure file has proper trailing newline before any edits
if [ -n "$(tail -c 1 "$MAKEPKG_CONF" 2>/dev/null)" ]; then
    echo "" >> "$MAKEPKG_CONF"
fi

modified=false

# 2. Configure BUILDDIR to build in high-speed RAM-disk /tmp/makepkg
if grep -q "^BUILDDIR=/tmp/makepkg" "$MAKEPKG_CONF"; then
    log_info "RAM-disk build directory already configured: BUILDDIR=/tmp/makepkg"
else
    log_info "Configuring RAM-disk build directory..."
    # Replace commented or existing BUILDDIR lines
    if grep -q "BUILDDIR=" "$MAKEPKG_CONF"; then
        sed -i 's|^#\?\s*BUILDDIR=.*|BUILDDIR=/tmp/makepkg|' "$MAKEPKG_CONF"
    else
        echo "BUILDDIR=/tmp/makepkg" >> "$MAKEPKG_CONF"
    fi
    log_success "Successfully set BUILDDIR=/tmp/makepkg"
    modified=true
fi

# 3. Configure MAKEFLAGS to use all CPU cores/threads dynamically
if grep -q '^MAKEFLAGS="-j\$(nproc)"' "$MAKEPKG_CONF" || grep -q '^MAKEFLAGS="-j\$(nproc)' "$MAKEPKG_CONF"; then
    log_info "Multi-threaded compilation already configured: MAKEFLAGS=\"-j\$(nproc)\""
else
    log_info "Configuring multi-threaded compilation..."
    if grep -q "MAKEFLAGS=" "$MAKEPKG_CONF"; then
        sed -i 's|^#\?\s*MAKEFLAGS=.*|MAKEFLAGS="-j$(nproc)"|' "$MAKEPKG_CONF"
    else
        echo 'MAKEFLAGS="-j$(nproc)"' >> "$MAKEPKG_CONF"
    fi
    log_success "Successfully set MAKEFLAGS=\"-j\$(nproc)\""
    modified=true
fi

# 4. Configure optimized compiler flags CFLAGS & CXXFLAGS for local native architecture
if grep -q "march=native" "$MAKEPKG_CONF"; then
    log_info "Native CFLAGS already configured (using -march=native)"
else
    log_info "Configuring Native instruction set CFLAGS..."
    # We safely append overrides at the end of the file to avoid corrupting multi-line flags
    echo "" >> "$MAKEPKG_CONF"
    echo "# Optimized Compiler Flags added by cachy-gnome-tweaks" >> "$MAKEPKG_CONF"
    echo 'CFLAGS="-march=native -O3 -pipe -fno-plt -fexceptions"' >> "$MAKEPKG_CONF"
    echo 'CXXFLAGS="$CFLAGS -Wp,-D_GLIBCXX_ASSERTIONS"' >> "$MAKEPKG_CONF"
    log_success "Successfully appended native CFLAGS & CXXFLAGS overrides"
    modified=true
fi

# 5. Configure multi-threaded package compression (Zstandard)
if grep -q "^COMPRESSZST=.*-T0" "$MAKEPKG_CONF" || grep -q "^COMPRESSZST=.*--threads=0" "$MAKEPKG_CONF"; then
    log_info "Multi-threaded package compression already configured"
else
    log_info "Configuring multi-threaded compression (zstd -T0)..."
    if grep -q "COMPRESSZST=" "$MAKEPKG_CONF"; then
        sed -i 's|^#\?\s*COMPRESSZST=.*|COMPRESSZST=(zstd -c -T0 -9 -)|' "$MAKEPKG_CONF"
    else
        echo "COMPRESSZST=(zstd -c -T0 -9 -)" >> "$MAKEPKG_CONF"
    fi
    log_success "Successfully set COMPRESSZST to multi-threaded mode (-T0)"
    modified=true
fi

if [ "$modified" = true ]; then
    log_success "makepkg Native Compiler & RAM-disk optimizations applied successfully!"
else
    log_info "All makepkg compiler optimizations are already active. System is fully optimized!"
fi
echo ""
