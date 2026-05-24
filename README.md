# 🏎️ cachy-gnome-tweaks

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![CachyOS](https://img.shields.io/badge/OS-CachyOS%20%2F%20Arch%20Linux-blue.svg)](https://cachyos.org/)
[![GNOME](https://img.shields.io/badge/Desktop-GNOME%20%2F%20Wayland-green.svg)](https://www.gnome.org/)

An optimized, modular, and non-destructive performance tuning and developer environment suite tailored specifically for **CachyOS running GNOME**. 

This project isolates and refactors high-grade backend improvements (NVIDIA GPU hardware acceleration variables, network latency tweaks, automatic BTRFS Snapper backup hooks, inotify file-watcher expansions, and pre-configured developer runtime shims) into a clean, interactive selector menu.

---

## ✨ Features

`cachy-gnome-tweaks` is fully interactive and completely optional—you choose exactly what optimizations to apply:

* **⚡ Module 1: NVIDIA Wayland & Electron HW Acceleration**
  * Auto-detects NVIDIA hardware.
  * Injects critical Wayland environment overrides (`__GLX_VENDOR_LIBRARY_NAME`, `GBM_BACKEND`, `NVD_BACKEND`, `ELECTRON_OZONE_PLATFORM_HINT`) to solve lag, screen-tearing, and rendering stutter in modern Electron apps and flatpaks.
  * Auto-injects VA-API hardware video decoding flags for Chromium-based browsers.
* **🌐 Module 2: Latency & Network Stability**
  * Configures advanced sysctl keepalive buffers and enables TCP MTU Probing to prevent high-latency dropouts and SSH disconnects.
  * Masks slow network-waiting services to accelerate system boot times.
  * Safely migrates NetworkManager to use the modern, lightweight `iwd` Wi-Fi backend (if installed) for fast wireless roaming.
* **📂 Module 3: Linux File Watchers (inotify) Expansion**
  * Automatically elevates maximum watcher limits to `524288` and instances to `512` to prevent editor crashes or frozen builds in large projects (VS Code, Neovim, Webpack, Vite, Node).
* **🛡️ Module 4: Snapper BTRFS Automated Backups & Boot Rollbacks**
  * Sets up BTRFS subvolume timeline parameters with automatic Hourly Cleaners.
  * Integrates Snapper directly into `pacman` using `snap-pac` to take system-state snapshots before and after every software installation.
  * Enables the `grub-btrfs` service, allowing you to **boot directly into older snapshots** straight from the GRUB boot menu if an update ever breaks your user session.
* **🛠️ Module 5: Developer Core Stack**
  * Verifies or bootstraps `yay` AUR helper integration.
  * Installs and configures [tmux](https://github.com/tmux/tmux) with mouse support, intuitive panel splitting bindings, and ultra-fast escape-latency.
  * Registers environment shims for [mise](https://mise.jdx.dev/) runtime manager dynamically inside `.bashrc` and `config.fish`.
* **📦 Module 6: Premium Apps Bundle (Optional)**
  * Installs **Vivaldi Browser** along with proprietary media codecs, GNOME Shell browser connector integration (`gnome-browser-connector`), and automatically sets up hardware accelerated video decoding (VA-API) in Vivaldi configuration flags for seamless YouTube/video rendering.
  * Deploys the high-fidelity **Audio Stack & Bluetooth Codecs** (LDAC, aptX) alongside `pavucontrol` (volume mixer GUI) for superior sound stability and control.
  * Installs essential **Compression, Disk & Archive Utilities** (`zip`, `unzip`, `unrar`, `p7zip`, `gparted`) to enable partition management alongside seamless extraction of `.zip`, `.rar`, and `.7z` files directly inside GNOME's default file manager.
  * Installs **MenuLibre** desktop menu editor, allowing you to easily customize, edit, or clean up your GNOME applications menu shortcuts.
* **🚀 Module 7: Easyarch App Pack (Optional)**
  * Install your favorite tools interactively or via CLI arguments:
    * **Telegram Desktop** for communication.
    * **Wine & Gaming Core Pack**: Optimised `wine-cachyos` execution base, `wine-mono`/`wine-gecko`, `winetricks`, graphical companion tools (`protonup-qt`, `protontricks`), full `cachyos-gaming-meta` stack, GNOME shell GameMode status indicator extension, and essential multilib 32-bit & 64-bit graphics/audio rendering drivers.
    * **GitHub Desktop** client for GUI git operations.
    * **Google Chrome** browser.
    * **OnlyOffice** suite with Spanish spelling dictionary support (`hunspell-es`).
    * **Antigravity IDE Launcher**: Global command `antigravity` and a GNOME `.desktop` shortcut that launches VS Code hooked with a persistent workspace tmux terminal.
    * **qBittorrent**: Lightweight, ad-free, open-source BitTorrent client.
* **🖥️ Module 8: Virtualization Stack (Optional)**
  * Complete high-performance **KVM/QEMU** virtualization environment setup.
  * Installs `virt-manager` GUI, `dnsmasq`, bridge interfaces, and automatically registers the active user in the `libvirt` system group.
* **🐋 Module 9: Docker Stack (Optional)**
  * Installs **Docker Engine & Docker Compose**.
  * Registers user in the `docker` group and configures **NVIDIA CUDA Container Toolkit** runtime hooks directly inside `/etc/docker/daemon.json`.
* **🧹 Module 10: Bloatware Remover (Optional)**
  * Interactively purges unused pre-installed applications like **Alacritty**, **GNOME Web (Epiphany)**, **GNOME Tour**, and other redundant utilities to keep your desktop system light and clean.
* **⚡ Module 11: makepkg Native Compiler & RAM-disk Optimization (Optional)**
  * Optimizes the Arch Linux compilation system (`/etc/makepkg.conf`) so that any package built from source (like emulators or AUR packages) compiles in a high-speed RAM-disk (`/tmp/makepkg`), utilizes all CPU cores/threads dynamically (`-j$(nproc)`), and leverages native processor instruction sets (`-march=native -O3`).

---

## 🚀 Interactive Installation

Getting started is as simple as cloning the repository and running the central orchestrator:

```bash
git clone https://github.com/esfingex/cachy-gnome-tweaks.git
cd cachy-gnome-tweaks
./bin/install.sh
```

### 📦 Requirements

* **Operating System**: CachyOS or any Arch Linux base system.
* **Shell Tools**: Bash or Fish.
* **Sudo Permissions**: Necessary to register kernel parameters (`sysctl`) and configure environment files.

---

## ⌨️ Independent CLI Usage

Each module can also be called directly as an independent installer script, bypassing the interactive main GUI menu. This is highly useful for automated provisioning or selective execution:

### 🚀 Easyarch App Installer (`easyarch.sh`)
Pass the names of the tools you want to install as CLI arguments:
```bash
sudo ./scripts/easyarch.sh telegram gaming-core onlyoffice chrome github antigravity qbittorrent
```
*Available argument options:* `telegram`, `gaming`, `github`, `chrome`, `onlyoffice`, `antigravity`, `qbittorrent`.

### 🤖 Gemini API CLI Helper (`gemini`)
Ask queries directly from your shell to Gemini 1.5 Flash:
```bash
gemini "write an automated python system-status parsing script"
```
*Note:* The key is saved securely in `~/.config/gemini_api_key`.

---

## 🛠️ Project Structure

```text
cachy-gnome-tweaks/
├── LICENSE                     # MIT Open Source License
├── README.md                   # Detailed user guide & overview
├── bin/
│   └── install.sh              # Main GUM-driven selector installer
├── config/
│   └── tmux.conf               # Elegant tmux shortcuts, truecolor support & split commands
└── scripts/
    ├── nvidia.sh               # Module 1: GPU rendering & electron overrides
    ├── network.sh              # Module 2: Sysctl network & NM iwd backend selector
    ├── file-watchers.sh        # Module 3: System inotify limits expansion
    ├── snapper.sh              # Module 4: Snapper configuration & grub-btrfs daemon hook
    ├── dev-tools.sh            # Module 5: User configurations, yay bootstrapper & mise shell configs
    ├── apps-bundle.sh          # Module 6: Vivaldi, Audio stack & BT codecs
    ├── easyarch.sh             # Module 7: Telegram, Wine & Gaming Core, GitHub Desktop, Chrome, OnlyOffice, Antigravity, qBittorrent (Calls antigravity.sh)
    ├── antigravity.sh          # Standalone: Dedicated premium Antigravity IDE setup & desktop shortcut
    ├── kvm-qemu.sh             # Module 8: KVM/QEMU hypervisor & bridges setup
    ├── docker-cuda.sh          # Module 9: Docker Engine & NVIDIA container toolkit hooks
    ├── debloat.sh              # Module 10: Interactive bloatware & unused apps remover
    └── makepkg.sh              # Module 11: makepkg compiler & RAM-disk optimizations
```

---

## 🔍 Troubleshooting & Logs

All installation runs write complete log outputs to `/tmp/cachy-gnome-tweaks.log` for debugging:

```bash
cat /tmp/cachy-gnome-tweaks.log
```

### 💡 Post-Installation Steps

1. **Session reload**: To activate environment variables, log out of GNOME and log back in, or run a full reboot.
2. **Developer Shells**: Start a new terminal window or run `source ~/.bashrc` (or `source ~/.config/fish/config.fish`) to load your new configurations and active shims.

---

## 📄 License

Distributed under the **MIT License**. See [LICENSE](file:///home/athena/Github/cachy-gnome-tweaks/LICENSE) for more details.
