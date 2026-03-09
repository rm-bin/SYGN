#!/bin/bash

set -e

# ────────────────────────────────────────────────
#  SYGN – Kiosk Installation Script
# ────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

info()    { echo -e "${CYAN}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

KIOSK_URL="${KIOSK_URL:-https://sygn.pages.dev}"

# ────────────────────────────────────────────────
# 1. System update & package install
# ────────────────────────────────────────────────
info "Updating system and installing packages..."
sudo apt update && sudo apt full-upgrade -y

sudo apt install -y --no-install-recommends \
  sway \
  xwayland \
  chromium \
  curl \
  wireguard \
  resolvconf
success "Packages installed."


# ────────────────────────────────────────────────
# 2. Download background image
# ────────────────────────────────────────────────
sudo mkdir -p /usr/share/backgrounds/
sudo curl -o /usr/share/backgrounds/wallpaper.png https://sygn.pages.dev/assets/wallpaper.png
sudo chmod 644 /usr/share/backgrounds/wallpaper.png

success "background image downloaded."

# ────────────────────────────────────────────────
# 3. Update SWAY config
# ────────────────────────────────────────────────
sudo sed -i '/^bar {/,/^}/d' /etc/sway/config # Remove bar

success "sway config updated."

# ────────────────────────────────────────────────
# 4. Create SWAY Custom Config
# ────────────────────────────────────────────────
sudo tee /etc/sway/config.d/90-sygn.conf > /dev/null <<EOF
output '*' bg "/usr/share/backgrounds/wallpaper.png" fill

# Disable titlebar on windows
default_border none

# Disable gaps
gaps inner 0
gaps outer 0

seat * hide_cursor when-typing enable
seat * hide_cursor 1
exec /usr/bin/chromium \\
    --ozone-platform=wayland \\
    --incognito \\
    --kiosk \\
    --disable-infobars \\
    --noerrdialogs \\
    --start-fullscreen \\
    --disable-restore-session-state \\
    --check-for-update-interval=31536000 \\
    ${KIOSK_URL}
EOF

success "sway custom config created."

# ────────────────────────────────────────────────
# 5. Create autologin for tty1
# ────────────────────────────────────────────────
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d/
sudo tee /etc/systemd/system/getty@tty1.service.d/autologin.conf > /dev/null <<EOF
[Service]
ExecStart=-/sbin/agetty --autologin $USER --noclear %I \$TERM
EOF

sudo systemctl daemon-reload

success "autologin for tty1 enabled."

# ────────────────────────────────────────────────
# 6. Create .bash_profile to autostart sway
# ────────────────────────────────────────────────
PROFILE_FILE="$HOME/.bash_profile"

# Remove existing sway autostart block if present
sudo sed -i '/# sway autostart/,/^fi$/d' "$PROFILE_FILE" 2>/dev/null || true

sudo tee "$PROFILE_FILE" > /dev/null <<EOF

# sway autostart
if [ -z "\$WAYLAND_DISPLAY" ] && [ "\$(tty)" = "/dev/tty1" ]; then
    exec sway
fi
EOF

success ".bash_profile updated."

# ────────────────────────────────────────────────
# Done
# ────────────────────────────────────────────────
echo ""
echo -e "${GREEN}╔═══════════════════════════════════╗${NC}"
echo -e "${GREEN}║    SYGN installation complete!    ║${NC}"
echo -e "${GREEN}║   Reboot to activate autostart.   ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════╝${NC}"
echo ""
read -rp "Reboot now? [y/N] " REBOOT
if [[ "$REBOOT" =~ ^[Yy]$ ]]; then
    sudo reboot
fi