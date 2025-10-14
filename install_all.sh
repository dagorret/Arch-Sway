#!/usr/bin/env bash
set -euo pipefail

# install_all.sh
# Detecta entorno y ejecuta el siguiente paso del pipeline:
# - Ubuntu HOST         -> 1_instalar_gnome_boxes.sh + 2_crear_vm_arch.sh
# - Arch LIVE ISO       -> 3_instalar_arch_auto.sh
# - Arch INSTALADO      -> 4_postinstall_sway.sh
#
# Uso rápido (sin clonar):
#   bash <(curl -fsSL https://raw.githubusercontent.com/dagorret/Arch-Sway/main/install_all.sh)

# ---------- Config ----------
RAW_BASE_DEFAULT="https://raw.githubusercontent.com/dagorret/Arch-Sway/main"
RAW_BASE="${RAW_BASE:-$RAW_BASE_DEFAULT}"

SCRIPT1="1_instalar_gnome_boxes.sh"
SCRIPT2="2_crear_vm_arch.sh"
SCRIPT3="3_instalar_arch_auto.sh"
SCRIPT4="4_postinstall_sway.sh"

# ---------- Helpers ----------
msg() { printf "\n\033[1;32m==>\033[0m %s\n" "$*"; }
warn() { printf "\n\033[1;33m!!\033[0m %s\n" "$*"; }
err() { printf "\n\033[1;31mEE\033[0m %s\n" "$*"; exit 1; }

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || return 1
}

ensure_curl() {
  if need_cmd curl; then return 0; fi
  msg "Instalando 'curl' (no encontrado)..."
  if [[ -r /etc/os-release ]]; then
    . /etc/os-release
    case "${ID:-}" in
      ubuntu|debian)
        sudo apt update && sudo apt install -y curl
        ;;
      arch)
        # En el LIVE ISO suele correrse como root (sin sudo).
        if [[ -d /run/archiso ]]; then
          pacman -Sy --noconfirm curl
        else
          sudo pacman -S --needed --noconfirm curl
        fi
        ;;
      *)
        err "Distribución no soportada automáticamente para instalar curl. Instálalo manualmente."
        ;;
    esac
  else
    err "No puedo detectar el sistema (falta /etc/os-release)."
  fi
}

run_remote() {
  local script_name="$1"
  local url="${RAW_BASE}/${script_name}"
  msg "Descargando y ejecutando: ${script_name}"
  bash <(curl -fsSL "$url")
}

detect_env() {
  # Devuelve uno de: ubuntu_host | arch_live | arch_installed | unknown
  if [[ -r /etc/os-release ]]; then
    . /etc/os-release
    case "${ID:-}" in
      ubuntu)
        echo "ubuntu_host"; return 0
        ;;
      arch)
        # LIVE ISO de Arch expone este directorio
        if [[ -d /run/archiso ]]; then
          echo "arch_live"; return 0
        else
          echo "arch_installed"; return 0
        fi
        ;;
    esac
  fi
  echo "unknown"
}

# ---------- Main ----------
msg "Determinando entorno..."
ensure_curl
ENV_KIND="$(detect_env)"
msg "Entorno detectado: ${ENV_KIND}"

case "$ENV_KIND" in
  ubuntu_host)
    msg "Secuencia para HOST Ubuntu:"
    msg "1) Instalar GNOME Boxes + stack de virtualización"
    run_remote "$SCRIPT1"

    msg "2) Crear la VM Arch Linux (descarga ISO + checksum + virt-install)"
    run_remote "$SCRIPT2"

    msg "Listo en el host. Abrí GNOME Boxes, arranca la VM desde la ISO y dentro del LIVE ejecutá:"
    echo "  bash <(curl -fsSL ${RAW_BASE}/${SCRIPT3})"
    ;;

  arch_live)
    msg "Secuencia para ARCH Live ISO:"
    # Chequeo rápido de red
    if ! ping -c1 -W2 archlinux.org >/dev/null 2>&1; then
      warn "No hay red. Configurá red (ip link / iwctl) antes de continuar."
      err "Abortando por falta de conectividad."
    fi
    run_remote "$SCRIPT3"
    msg "Reiniciá y expulsá la ISO para bootear desde disco. Luego en el sistema instalado ejecutá:"
    echo "  bash <(curl -fsSL ${RAW_BASE}/${SCRIPT4})"
    ;;

  arch_installed)
    msg "Secuencia para ARCH instalado (post-reboot):"
    # Recomendación: NO ejecutar como root (el SCRIPT4 verifica esto de todas formas)
    if [[ "$EUID" -eq 0 ]]; then
      warn "Estás corriendo como root. Se recomienda ejecutar como usuario normal con sudo configurado."
    fi
    run_remote "$SCRIPT4"
    msg "Completado. Iniciá el entorno con: sway-start"
    ;;

  *)
    err "No pude identificar el entorno automáticamente. Ejecutá los scripts manualmente."
    ;;
esac
