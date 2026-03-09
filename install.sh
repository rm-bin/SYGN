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

KIOSK_URL="${KIOSK_URL:-https://sygn.pages.dev/default.html}"

# ────────────────────────────────────────────────
# 1. System update & package install
# ────────────────────────────────────────────────
info "Updating system and installing packages..."
sudo apt update && sudo apt full-upgrade -y
sudo apt install -y chromium wireguard wlrctl resolvconf
success "Packages installed."

# ────────────────────────────────────────────────
# 2. Disable screensaver & auto-update timers
# ────────────────────────────────────────────────
info "Disabling screensaver and apt timers..."
sudo systemctl mask xscreensaver.service         2>/dev/null || true
sudo systemctl disable apt-daily.timer           2>/dev/null || true
sudo systemctl disable apt-daily-upgrade.timer   2>/dev/null || true
sudo systemctl stop    apt-daily.timer           2>/dev/null || true
sudo systemctl stop    apt-daily-upgrade.timer   2>/dev/null || true
success "Screensaver and update timers disabled."

# ────────────────────────────────────────────────
# 3. Disable LXDE screensaver / power management
# ────────────────────────────────────────────────
AUTOSTART_FILE="/etc/xdg/lxsession/LXDE-pi/autostart"
if [ -f "$AUTOSTART_FILE" ]; then
    info "Patching LXDE autostart to disable screensaver..."
    sudo sed -i 's|^@xscreensaver.*||g' "$AUTOSTART_FILE"
    # Ensure xset commands are present to turn off DPMS / screen blanking
    grep -qxF '@xset s off'         "$AUTOSTART_FILE" || echo '@xset s off'         | sudo tee -a "$AUTOSTART_FILE" > /dev/null
    grep -qxF '@xset -dpms'         "$AUTOSTART_FILE" || echo '@xset -dpms'         | sudo tee -a "$AUTOSTART_FILE" > /dev/null
    grep -qxF '@xset s noblank'     "$AUTOSTART_FILE" || echo '@xset s noblank'     | sudo tee -a "$AUTOSTART_FILE" > /dev/null
    success "LXDE autostart patched."
else
    warn "$AUTOSTART_FILE not found - skipping LXDE patch."
fi

# ────────────────────────────────────────────────
# 4. Create kiosk startup script
# ────────────────────────────────────────────────
STARTUP_SCRIPT="$HOME/.config/autostart/start-screen.sh"
info "Creating kiosk startup script at $STARTUP_SCRIPT..."
mkdir -p "$HOME/.config/autostart"

cat > "$STARTUP_SCRIPT" << EOF
#!/bin/bash
DISPLAY=:0 /usr/bin/chromium \\
    --incognito \\
    --kiosk \\
    --disable-infobars \\
    --noerrdialogs \\
    --start-fullscreen \\
    ${KIOSK_URL} &

sleep 15
WAYLAND_DISPLAY=wayland-0 /usr/bin/wlrctl pointer move 99999 99999
wait
EOF

chmod +x "$STARTUP_SCRIPT"
success "Startup script created and made executable."

# ────────────────────────────────────────────────
# 5. Create .desktop autostart entry
# ────────────────────────────────────────────────
DESKTOP_FILE="$HOME/.config/autostart/sygn.desktop"
info "Creating autostart .desktop entry at $DESKTOP_FILE..."

cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Type=Application
Name=Start SYGN
Exec=bash ${STARTUP_SCRIPT}
X-GNOME-Autostart-enabled=true
EOF

success ".desktop entry created."

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