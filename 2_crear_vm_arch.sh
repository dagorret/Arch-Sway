#!/usr/bin/env bash
set -euo pipefail

# ==========================================================
# Script: 2_crear_vm_arch.sh (session/system)
# Crea una VM Arch lista para GNOME Boxes.
# - session: usa --network user (SLIRP)
# - system : usa --network network=default
# ==========================================================

VM_NAME="${VM_NAME:-arch-sway}"
ISO_DIR="${ISO_DIR:-$HOME/ISOs}"
ISO_PATH="$ISO_DIR/archlinux-x86_64.iso"
SHA_FILE="$ISO_DIR/sha256sums.txt"

DISK_SIZE_GB="${DISK_SIZE_GB:-20}"
RAM_MB="${RAM_MB:-4096}"
VCPUS="${VCPUS:-4}"

# Alcance: session (Boxes) | system (virt-manager)
LIBVIRT_SCOPE="${LIBVIRT_SCOPE:-session}"
case "$LIBVIRT_SCOPE" in
  session) CONNECT_URI="qemu:///session"; VM_STORAGE_DIR="$HOME/.local/share/libvirt/images" ;;
  system)  CONNECT_URI="qemu:///system";  VM_STORAGE_DIR="/var/lib/libvirt/images" ;;
  *) echo "EE Alcance inválido: $LIBVIRT_SCOPE (use: session|system)"; exit 1 ;;
esac

DISK_PATH="${VM_STORAGE_DIR}/${VM_NAME}.qcow2"

msg()  { printf "\n\033[1;32m==>\033[0m %s\n" "$*"; }
warn() { printf "\n\033[1;33m!!\033[0m %s\n" "$*"; }
err()  { printf "\n\033[1;31mEE\033[0m %s\n" "$*"; exit 1; }
need() { command -v "$1" >/dev/null 2>&1 || err "Falta comando: $1"; }

for c in curl qemu-img virt-install sha256sum; do need "$c"; done
[[ "$LIBVIRT_SCOPE" == "system" ]] && need sudo

# --- Directorios ---
mkdir -p "$ISO_DIR"
if [[ "$LIBVIRT_SCOPE" == "session" ]]; then
  mkdir -p "$VM_STORAGE_DIR"
else
  sudo mkdir -p "$VM_STORAGE_DIR"
fi

# --- ISO + checksum ---
ISO_URL="https://geo.mirror.pkgbuild.com/iso/latest/archlinux-x86_64.iso"
SUMS_URL="https://geo.mirror.pkgbuild.com/iso/latest/sha256sums.txt"

msg "Descargando ISO de Arch (si no existe)..."
[[ -f "$ISO_PATH" ]] || curl -L --fail -o "$ISO_PATH" "$ISO_URL"

msg "Descargando sha256sums.txt..."
curl -L --fail -o "$SHA_FILE" "$SUMS_URL"

msg "Verificando checksum SHA256..."
( cd "$ISO_DIR" && sha256sum -c --ignore-missing sha256sums.txt )
msg "Checksum OK."

# ISO accesible para libvirt
if [[ "$LIBVIRT_SCOPE" == "session" ]]; then
  ISO_FOR_VM="$ISO_PATH"
else
  ISO_BASENAME="$(basename "$ISO_PATH")"
  if [[ ! -r "$VM_STORAGE_DIR/$ISO_BASENAME" ]]; then
    msg "Copiando ISO a $VM_STORAGE_DIR (system)..."
    sudo cp "$ISO_PATH" "$VM_STORAGE_DIR/"
  fi
  ISO_FOR_VM="$VM_STORAGE_DIR/$ISO_BASENAME"
fi

# --- Disco qcow2 ---
msg "Creando disco qcow2 ${DISK_SIZE_GB}G en: $DISK_PATH"
if [[ "$LIBVIRT_SCOPE" == "session" ]]; then
  [[ -f "$DISK_PATH" ]] || qemu-img create -f qcow2 "$DISK_PATH" "${DISK_SIZE_GB}G"
else
  [[ -f "$DISK_PATH" ]] || sudo qemu-img create -f qcow2 "$DISK_PATH" "${DISK_SIZE_GB}G"
fi

# --- OVMF (UEFI) opcional (Ubuntu/Debian) ---
if command -v dpkg >/dev/null 2>&1; then
  if ! dpkg -s ovmf &>/dev/null; then
    warn "OVMF no está instalado. Intentando instalar..."
    sudo apt update && sudo apt install -y ovmf || warn "No se pudo instalar OVMF automáticamente."
  fi
fi
OVMF_CODE="/usr/share/OVMF/OVMF_CODE.fd"
OVMF_VARS="/usr/share/OVMF/OVMF_VARS.fd"
BOOT_OPTS=()
if [[ -r "$OVMF_CODE" && -r "$OVMF_VARS" ]]; then
  msg "Usando UEFI (OVMF)."
  BOOT_OPTS=( --boot loader="$OVMF_CODE",loader.readonly=yes,loader.type=pflash,nvram.template="$OVMF_VARS" )
else
  warn "OVMF no disponible; se usará BIOS legado."
fi

# --- Red según alcance ---
if [[ "$LIBVIRT_SCOPE" == "session" ]]; then
  # En session NO hay 'default'; usar SLIRP (user) para salir a Internet
  NET_ARGS=( --network user,model=virtio )
else
  # En system se asume red 'default' gestionada por libvirt
  # Si no existe: sudo virsh net-start default && sudo virsh net-autostart default
  NET_ARGS=( --network network=default,model=virtio )
fi

# --- Crear VM ---
msg "Creando VM ${VM_NAME} en ${CONNECT_URI} ..."
virt-install \
  --connect "$CONNECT_URI" \
  --name "$VM_NAME" \
  --memory "$RAM_MB" \
  --vcpus "$VCPUS" \
  --cpu host-passthrough \
  --disk path="$DISK_PATH",format=qcow2,bus=virtio \
  --cdrom "$ISO_FOR_VM" \
  "${NET_ARGS[@]}" \
  --graphics spice,listen=none,gl=on \
  --video virtio \
  --sound ich9 \
  --rng /dev/urandom \
  --os-variant archlinux \
  "${BOOT_OPTS[@]}" \
  --noautoconsole || err "Error al crear la VM."

msg "✅ VM creada."
if [[ "$LIBVIRT_SCOPE" == "session" ]]; then
  msg "Abrí GNOME Boxes (modo normal) → Deberías ver '${VM_NAME}'."
else
  msg "Abrí GNOME Boxes con: gnome-boxes --system (o usá virt-manager)."
fi

msg "Dentro del live ISO, ejecutá:"
echo "    bash <(curl -fsSL https://raw.githubusercontent.com/dagorret/Arch-Sway/main/3_instalar_arch_auto.sh)"
