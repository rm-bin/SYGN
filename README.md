<p align="center">
    <img src="assets/logo_large.svg" alt="SYGN" width="256">
</p>

# Installation command

```bash
curl -fsSL https://sygn.pages.dev/install.sh | bash
```

# Manual installation

> [!NOTE]
> If you are on Ubuntu replace every occurence of `chromium` with `chromium-browser`

## Updates & Install packages

```bash
sudo apt update && sudo apt full-upgrade -y
sudo apt install -y --no-install-recommends sway xwayland chromium sway-backgrounds
```

## Create necessary files

### Optional: Set Wallpaper

```bash
sudo mkdir -p /usr/share/backgrounds/
sudo curl -o /usr/share/backgrounds/wallpaper.png https://sygn.pages.dev/assets/wallpaper.png
sudo chmod 644 /usr/share/backgrounds/wallpaper.png
```

Replace `https://sygn.pages.dev/assets/wallpaper.png` with your own image link.

### Create Sway Custom Config

```bash
sudo nano /etc/sway/config.d/90-sygn.conf
```

```bash
# remove this line if you did not create a custom wallpaper as shown earlier
output '*' bg "/usr/share/backgrounds/wallpaper.png" fill

# Disable titlebar on windows
default_border none

# Disable gaps
gaps inner 0
gaps outer 0

seat * hide_cursor when-typing enable
seat * hide_cursor 1

exec_always bash -c 'sleep 1 && swaymsg bar mode invisible'
exec sleep 5 && /usr/bin/chromium \
    --ozone-platform=wayland \
    --incognito \
    --kiosk \
    --disable-infobars \
    --noerrdialogs \
    --no-first-run \
    --start-fullscreen \
    --disable-restore-session-state \
    --check-for-update-interval=31536000 \
    https://sygn.pages.dev
```

### Create Cromium Custom Config

```bash
sudo mkdir -p /etc/chromium/policies/managed/
sudo nano /etc/chromium/policies/managed/extra_settings.json
```

```json
{
    "TranslateEnabled": false
}
```

### Create autologin for tty1

```bash
sudo mkdir -p /etc/systemd/system/getty@tty1.service.d/
sudo nano /etc/systemd/system/getty@tty1.service.d/autologin.conf
```

```ini
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $USER --noclear %I \$TERM
```

```bash
sudo systemctl daemon-reload
```

### Create `.bash_profile` to autostart sway

#### Remove existing sway autostart block if present

```bash
sudo sed -i '/# sway autostart/,/^fi$/d' "~/.bash_profile" 2>/dev/null || true
```

#### Edit `.bash_profile`

```bash
sudo nano ~/.bash_profile
```

```bash
# sway autostart
if [ -z "\$WAYLAND_DISPLAY" ] && [ "\$(tty)" = "/dev/tty1" ]; then
    exec sway
fi
```
