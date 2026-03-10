#!/bin/bash

cleanup() {
    tput sgr0
    tput cnorm
    info "\nSYGN Setup exited."
    exit 1
}

trap cleanup SIGINT SIGTERM

set -e

# ────────────────────────────────────────────────
#  SYGN – Kiosk Installation Script
# ────────────────────────────────────────────────

GREEN=$'\033[0;32m'
CYAN=$'\033[0;36m'
BOLD=$'\033[1m'
NC=$'\033[0m'


log_info()    { printf "\033[37;44m%s  INFO  %s %b" "${BOLD}" "${NC}" "$*"; }
log_success() { printf "\033[37;42m%s   OK   %s %b" "${BOLD}" "${NC}" "$*"; }
log_warn()    { printf "\033[37;43m%s  WARN  %s %b" "${BOLD}" "${NC}" "$*"; }
log_error()   { printf "\033[37;41m%s ERROR! %s %b" "${BOLD}" "${NC}" "$*"; }

info()    { log_info "$*\n"; }
success() { log_success "$*\n"; }
warn()    { log_warn "$*\n"; }
error()   { log_error "$*\n"; }

clear

echo "${GREEN}${BOLD}"
echo ""
echo ""
echo "           000100000001010110000111001001001000111001000110110101   "
echo "         0011000100111111011110000100110110110101001101101101100001 "
echo "        01111                                                  01001"
echo "        1011                                                    0110"
echo "        0110       011111011010          01101000       0101    0000"
echo "        1000     1001100000010010      011111001010     0110    1000"
echo "        1011    10100        010100  011011    001111   1001    1001"
echo "        0110    0011           0001110100        011000 0000    0110"
echo "        0101    01000011001      111110            011101001    1100"
echo "        1111     100110010111     1001     0011      0000101    0011"
echo "        0001       10010000100    0110     100111      10100    0101"
echo "        0000              1111    1010       11011      0010    1110"
echo "        0111    10000    00100    00011      11000      1100    0111"
echo "        1011     100111001010      10110011011000       1001    1100"
echo "        0110       10011101          1100100011         1010    1100"
echo "        1110                                                    0001"
echo "        10010                                                  11101"
echo "         0000111010111100100010000010101101000000111101010000101101 "
echo "           101001001110111101101011111010001011101100010011101011   "
echo ""
echo ""
echo "${NC}"


OS=$(grep -w "ID" /etc/os-release | cut -d "=" -f 2 | tr -d '"')
BROWSER=""

case "$OS" in
    "ubuntu")
        BROWSER=chromium-browser
        info "Detected Ubuntu."
        ;;
    "debian")
        BROWSER=chromium
        info "Detected Debian."
        ;;
    *)
        IGNORE_OS_WARNING="n"
        read -rp "Unsupported OS: $OS. Continue anyway? [y/n] " IGNORE_OS_WARNING </dev/tty
        if [[ ! "$IGNORE_OS_WARNING" =~ ^[Yy]$ ]]; then
            info "SYGN Setup exited"
            exit 1
        fi
        BROWSER=chromium
        ;;
esac

KIOSK_URL="${KIOSK_URL:-https://sygn.pages.dev}"
CORRECT="n"
STATUS_CODE="000"
IGNORE_NOT_REACHABLE="n"

while [[ ! "$CORRECT" =~ ^[Yy]$ || ! "$IGNORE_NOT_REACHABLE" =~ ^[Yy]$ ]]; do
    read -rp $'Which Website should be displayed? default: https://sygn.pages.dev\n> '"$CYAN" KIOSK_URL </dev/tty
    printf "%s" "${NC}"
    if [[ "$KIOSK_URL" == "" ]]; then
        KIOSK_URL="https://sygn.pages.dev"
        CORRECT="y"
        break
    fi

    read -rp "Is this correct? [y/n] " CORRECT </dev/tty
    if [[ ! "$CORRECT" =~ ^[Yy]$ ]]; then
        continue
    fi

    STATUS_CODE=$(curl -o /dev/null -sw "%{http_code}" "$KIOSK_URL")
    if [[ "$STATUS_CODE" != "200" ]]; then
        log_warn ""
        read -rp "Site not reachable. Continue anyway? [y/n] " IGNORE_NOT_REACHABLE </dev/tty
    else 
        IGNORE_NOT_REACHABLE="y"
    fi
done

# ────────────────────────────────────────────────
# 1. System update & package install
# ────────────────────────────────────────────────
info "Updating system and installing packages..."
sudo apt update && sudo apt full-upgrade -y

sudo apt install -y --no-install-recommends \
    sway \
    xwayland \
    $BROWSER \
    sway-backgrounds
success "Packages installed."


# ────────────────────────────────────────────────
# 2. Download background image
# ────────────────────────────────────────────────
sudo mkdir -p /usr/share/backgrounds/
sudo curl -o /usr/share/backgrounds/wallpaper.png https://sygn.pages.dev/assets/wallpaper.png
sudo chmod 644 /usr/share/backgrounds/wallpaper.png

success "Background image downloaded."

# ────────────────────────────────────────────────
# 3. Create SWAY Custom Config
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

exec_always bash -c 'sleep 1 && swaymsg bar mode invisible'
exec sleep 5 && /usr/bin/$BROWSER \\
    --ozone-platform=wayland \\
    --incognito \\
    --kiosk \\
    --disable-infobars \\
    --noerrdialogs \\
    --no-first-run \\
    --start-fullscreen \\
    --disable-restore-session-state \\
    --check-for-update-interval=31536000 \\
    ${KIOSK_URL}
EOF

success "sway custom config created."

# ────────────────────────────────────────────────
# 4. Create autologin for tty1
# ────────────────────────────────────────────────
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d/
sudo tee /etc/systemd/system/getty@tty1.service.d/autologin.conf > /dev/null <<EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $USER --noclear %I \$TERM
EOF

sudo systemctl daemon-reload

success "autologin for tty1 enabled."

# ────────────────────────────────────────────────
# 5. Create .bash_profile to autostart sway
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
read -rp "Reboot now? [y/n] " REBOOT </dev/tty
if [[ "$REBOOT" =~ ^[Yy]$ ]]; then
    sudo reboot
fi
