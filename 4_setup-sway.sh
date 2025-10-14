#!/usr/bin/env bash
set -euo pipefail

### Arch + Sway preset (Firefox, Thunar, Mousepad, Emacs Wayland, MarkText, Pandoc + TeX Live full-like,
### estética completa, utilidades de confort y entorno de desarrollo)
### Este script es para correr en Arch ya instalado (después del primer reboot).

# ---------- Helpers ----------
msg() { printf "\n\033[1;32m==>\033[0m %s\n" "$*"; }
warn() { printf "\n\033[1;33m!!\033[0m %s\n" "$*"; }
err() { printf "\n\033[1;31mEE\033[0m %s\n" "$*"; exit 1; }

[[ $EUID -eq 0 ]] && err "Ejecutá este script como USUARIO NORMAL (no root). Usa sudo cuando se pida."

# ---------- Actualización base ----------
msg "Actualizando sistema..."
sudo pacman -Syu --noconfirm

# ---------- Paquetes base Sway + Wayland ----------
msg "Instalando Sway + Wayland y utilidades base..."
sudo pacman -S --needed --noconfirm \
  sway wayland wlroots xorg-xwayland xdg-desktop-portal-wlr \
  alacritty foot waybar wofi mako swaybg wl-clipboard \
  pavucontrol brightnessctl \
  firefox thunar mousepad \
  networkmanager network-manager-applet \
  blueman bluez bluez-utils \
  grim slurp htop btop neofetch

# Audio moderno (PipeWire)
msg "Instalando PipeWire (audio) y habilitando servicios..."
sudo pacman -S --needed --noconfirm pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber
# Servicios de usuario (pueden fallar si no hay session activa de systemd --user; no es grave)
systemctl --user enable --now pipewire.service pipewire-pulse.service wireplumber.service || true
# Servicios de sistema
sudo systemctl enable --now NetworkManager
sudo systemctl enable --now bluetooth

# ---------- Entorno de desarrollo ----------
msg "Instalando entorno de desarrollo..."
sudo pacman -S --needed --noconfirm git base-devel gcc make python python-pip neovim nano

# ---------- Emacs (Wayland/PGTK si existe; si no, Emacs estándar) ----------
msg "Instalando Emacs (Wayland si está disponible)..."
if sudo pacman -Si emacs-pgtk-nativecomp &>/dev/null; then
  sudo pacman -S --needed --noconfirm emacs-pgtk-nativecomp
elif sudo pacman -Si emacs-pgtk &>/dev/null; then
  sudo pacman -S --needed --noconfirm emacs-pgtk
else
  warn "Paquete Emacs PGTK no disponible; instalando emacs estándar."
  sudo pacman -S --needed --noconfirm emacs
fi

# ---------- Fuentes, temas y esquemas GTK (estética robusta) ----------
msg "Instalando fuentes, temas e iconos..."
sudo pacman -S --needed --noconfirm \
  ttf-dejavu noto-fonts noto-fonts-emoji noto-fonts-cjk \
  arc-gtk-theme papirus-icon-theme gsettings-desktop-schemas libappindicator-gtk3

# ---------- Pandoc + TeX Live (conjunto amplio, equivalente a 'full') ----------
msg "Instalando Pandoc + TeX Live amplio (full-like)..."
sudo pacman -S --needed --noconfirm pandoc \
  texlive-basic texlive-binextra texlive-latex texlive-latexrecommended \
  texlive-latexextra texlive-pictures texlive-science texlive-bibtexextra \
  texlive-fontsextra ghostscript

# ---------- Directorios de usuario (Documentos, Descargas, etc.) ----------
msg "Creando carpetas estándar de usuario..."
sudo pacman -S --needed --noconfirm xdg-user-dirs
xdg-user-dirs-update

# ---------- AUR helper (yay) para instalar MarkText ----------
msg "Instalando yay (AUR helper) para MarkText..."
if ! command -v yay &>/dev/null; then
  WORKDIR="$(mktemp -d)"
  pushd "$WORKDIR" >/dev/null
  # Asegurar prerequisitos
  sudo pacman -S --needed --noconfirm go git base-devel
  git clone https://aur.archlinux.org/yay.git
  pushd yay >/dev/null
  makepkg -si --noconfirm
  popd >/dev/null
  popd >/dev/null
  rm -rf "$WORKDIR" || true
else
  msg "yay ya está instalado."
fi

# MarkText (AUR). Alternativa: ghostwriter (repos oficiales)
msg "Instalando MarkText desde AUR..."
if ! yay -S --noconfirm --needed marktext-bin; then
  warn "Falló la instalación de MarkText desde AUR. Instalando 'ghostwriter' como alternativa."
  sudo pacman -S --needed --noconfirm ghostwriter
fi

# ---------- Configuración mínima de Sway / Waybar / Wofi / Mako ----------
msg "Creando configuración mínima en ~/.config ..."
mkdir -p ~/.config/sway ~/.config/waybar ~/.config/wofi ~/.config/mako ~/.config/gtk-3.0

# Sway config básica con atajos comunes y tema
cat > ~/.config/sway/config <<'SWAYCFG'
# Sway config mínima
set $mod Mod4
font pango:Noto Sans 11

# Terminal y lanzador
set $term foot
set $menu wofi --show drun

# Layouts y atajos
bindsym $mod+Return exec $term
bindsym $mod+d exec $menu
bindsym $mod+Shift+e exec "swaymsg exit"
bindsym $mod+Shift+q kill
bindsym $mod+f fullscreen toggle
bindsym $mod+h split h
bindsym $mod+v split v
bindsym $mod+space floating toggle
bindsym $mod+Shift+space focus mode_toggle
bindsym $mod+Left focus left
bindsym $mod+Right focus right
bindsym $mod+Up focus up
bindsym $mod+Down focus down

# Volumen / brillo
bindsym XF86AudioRaiseVolume exec 'pactl set-sink-volume @DEFAULT_SINK@ +5%'
bindsym XF86AudioLowerVolume exec 'pactl set-sink-volume @DEFAULT_SINK@ -5%'
bindsym XF86AudioMute exec 'pactl set-sink-mute @DEFAULT_SINK@ toggle'
bindsym XF86MonBrightnessUp exec 'brightnessctl set +5%'
bindsym XF86MonBrightnessDown exec 'brightnessctl set 5%-'

# Barra
bar {
  position top
  status_command waybar
}

# Fondo (color liso por defecto)
output * bg #2b2b2b solid_color

# Cursor
seat * hide_cursor 3000

# GTK Theme (Arc) e iconos (Papirus) – por gsettings (puede no aplicar según entorno)
exec_always {
  gsettings set org.gnome.desktop.interface gtk-theme 'Arc-Dark'
  gsettings set org.gnome.desktop.interface icon-theme 'Papirus'
  gsettings set org.gnome.desktop.interface font-name 'Noto Sans 11'
}

# Notificaciones (mako)
exec mako
SWAYCFG

# Waybar: config simple con módulos útiles
cat > ~/.config/waybar/config <<'WAYBARCFG'
{
  "layer": "top",
  "position": "top",
  "modules-left": ["sway/workspaces", "sway/mode"],
  "modules-center": ["clock"],
  "modules-right": ["tray", "network", "bluetooth", "cpu", "memory", "pulseaudio"],
  "clock": { "format": "{:%a %d %b %H:%M}" },
  "cpu": { "interval": 3 },
  "memory": { "interval": 5, "format": "{used}/{total} GiB" },
  "network": { "format-wifi": "{essid} {signalStrength}%" },
  "pulseaudio": { "format": "{volume}% {icon}" },
  "tray": { "spacing": 8 }
}
WAYBARCFG

# Waybar style acorde a Arc-Dark
cat > ~/.config/waybar/style.css <<'WAYBARCSS'
* { font-family: "Noto Sans"; font-size: 12px; }
window { background: #2b2b2b; color: #ddd; }
#workspaces button.focused, #mode { background: #3c6eb4; color: #fff; }
#clock, #cpu, #memory, #network, #pulseaudio, #bluetooth, #tray { padding: 0 8px; }
WAYBARCSS

# Wofi: tema dark simple
cat > ~/.config/wofi/style.css <<'WOFICSS'
window { background-color: #2b2b2b; }
#entry, #input { color: #eee; }
WOFICSS

# Mako: notificaciones
cat > ~/.config/mako/config <<'MAKOCFG'
background-color=#2b2b2b
text-color=#eeeeee
border-color=#3c6eb4
default-timeout=5000
MAKOCFG

# GTK-3 fallback (en caso de que gsettings no aplique)
cat > ~/.config/gtk-3.0/settings.ini <<'GTKSET'
[Settings]
gtk-theme-name=Arc-Dark
gtk-icon-theme-name=Papirus
font-name=Noto Sans 11
GTKSET

# ---------- Lanzador con fallback automático (software si falla 3D) ----------
sudo install -Dm755 /dev/stdin /usr/local/bin/sway-start <<'LAUNCHER'
#!/usr/bin/env bash
# Intenta lanzar Sway con renderizado normal; si falla, usa software
exec sway || { echo "[sway-start] Reintentando con WLR_RENDERER_ALLOW_SOFTWARE=1"; WLR_RENDERER_ALLOW_SOFTWARE=1 exec sway; }
LAUNCHER

msg "Listo. Podés iniciar Sway ejecutando:  sway-start"
msg "Si no escuchás audio, probá: systemctl --user restart wireplumber pipewire pipewire-pulse"
msg "Carpetas de usuario creadas. Si querés personalizarlas: xdg-user-dirs-update --force"
