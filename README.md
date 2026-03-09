<p align="center">
    <img src="assets/logo_large.svg" alt="SYGN" width="256">
</p>

## Installation command (comming soon)

```bash
...
```

## Manual installation

### Updates & Install packages

```bash
sudo apt update && sudo apt full-upgrade
sudo apt install chromium wireguard wlrctl resolvconf -y
```

### Disable Screensaver

```bash
sudo systemctl mask xscreensaver.service
sudo systemctl disable apt-daily.timer
sudo systemctl disable apt-daily-upgrade.timer
sudo systemctl stop apt-daily.timer
sudo systemctl stop apt-daily-upgrade.timer
```

### Create necessary files

#### `start-screen.sh`

```bash
mkdir -p ~/.config/autostart
sudo nano ~/.config/autostart/start-screen.sh
```

```bash
DISPLAY=:0 /usr/bin/chromium --incognito --kiosk --disable-infobars --noerrdialogs --start-fullscreen https://sygn.pages.dev/default.html &
sleep 15
WAYLAND_DISPLAY=wayland-0 /usr/bin/wlrctl pointer move 100 100
wait
```

`CTRL` + `S` → Save\
`CTRL` + `X` → Exit

> [!TIP]
> https://sygn.pages.dev/default.html

##### Make file executable

```bash
sudo chmod +x ~/.config/autostart/start-screen.sh
```

#### `sygn.desktop`

```ini
[Desktop Entry]
Type=Application
Name=Start SYGN
Exec=bash screen.sh
X-GNOME-Autostart-enabled=true
```

---

### Optional: Wireguard to visit privately hosted websites

#### Create Wireguard Config

```bash
sudo nano /etc/wireguard/wg0.conf
```

#### Make it editable for owner

```bash
sudo chmod 600 /etc/wireguard/wg0.conf
```

#### Edit the Config

```bash
sudo systemctl edit wg-quick@wg0
```

```ini
[Interface]
PrivateKey = ...
Address = ...
DNS = ...

[Peer]
PublicKey = ...
AllowedIPs = ...
Endpoint = ...
```

#### Enable it

```bash
sudo systemctl enable wg-quick@wg0
```
