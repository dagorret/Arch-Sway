#!/usr/bin/env bash
set -euo pipefail

# ==========================================================
# Script: 2_crear_vm_arch.sh
# Crea una VM Arch Linux con libvirt/virt-install
# Detecta OVMF (UEFI), valida ISO con SHA256, y maneja permisos de acceso.
# ==========================================================

VM_NAME="${VM_NAME:-arch-sway}"
ISO_DIR="${ISO_DIR:-$HOME/ISOs}"
ISO_PATH="$ISO_DIR/archlinux-x86_64.iso"
SHA_FILE="$ISO_DIR/sha256sums.txt"

# Carpeta donde libvirt tiene acceso por defecto
VM_STORAGE_DIR="/var/lib/libvirt/images"
DISK_PATH="${VM_STORAGE_DIR}/${VM_NAME}.qcow2"

DISK_SIZE_GB="${DISK_SIZE_GB:-20}"   # 20 GB dinámicos
RAM_MB="${RAM_MB:-4096}"             # 4 GB RAM
VCPUS="${VCPUS:-4}"                  # 4 vCPU

# --- Helper functions ---
msg() { printf "\n\033[1;32m==>\033[0m %s\n" "$*"; }
warn() { printf "\n\033[1;33m!!\033[0m %s\n" "$*"; }
err() { printf "\n\033[1;31mEE\033[0m %s\n" "$*"; exit 1; }

# --- Check dependencies ---
for cmd in curl qemu-img virt-install; do
  command -v "$cmd" >/dev/null || err "Falta el comando '$cmd'. Instalalo primero."
done

# --- Prepare directories ---
sudo mkdir -p "$VM_STORAGE_DIR"
mkdir -p "$ISO_DIR"

# --- Descargar ISO + checksum ---
ISO_URL="https://geo.mirror.pkgbuild.com/iso/latest/archlinux-x86_64.iso"
SUMS_URL="https://geo.mirror.pkgbuild.com/iso/latest/sha256sums.txt"

msg "Descargando ISO de Arch (si no existe)..."
if [[ ! -f "$ISO_PATH" ]]; then
  curl -L --fail -o "$ISO_PATH" "$ISO_URL"
fi

msg "Descargando sha256sums.txt..."
curl -L --fail -o "$SHA_FILE" "$SUMS_URL"

msg "Verificando checksum SHA256 de la ISO..."
(
  cd "$ISO_DIR"
  if ! sha256sum -c --ignore-missing "sha256sums.txt"; then
    err "Checksum SHA256 NO coincide. Borra la ISO y reintentá."
  fi
)
msg "Checksum OK."

# --- Copiar ISO si libvirt no tiene acceso a HOME ---
if [[ ! -r "$VM_STORAGE_DIR/$(basename "$ISO_PATH")" ]]; then
  msg "Copiando ISO a ${VM_STORAGE_DIR} (accesible por libvirt)..."
  sudo cp "$ISO_PATH" "$VM_STORAGE_DIR/"
fi
ISO_VM_PATH="${VM_STORAGE_DIR}/$(basename "$ISO_PATH")"

# --- Crear disco qcow2 ---
msg "Creando disco qcow2 ${DISK_SIZE_GB}G en: $DISK_PATH"
if [[ ! -f "$DISK_PATH" ]]; then
  sudo qemu-img create -f qcow2 "$DISK_PATH" "${DISK_SIZE_GB}G"
else
  warn "El disco ya existe, se usará el existente."
fi

# --- Detectar OVMF (UEFI) ---
OVMF_CODE="/usr/share/OVMF/OVMF_CODE.fd"
OVMF_VARS="/usr/share/OVMF/OVMF_VARS.fd"
BOOT_OPTS=()
if [[ -r "$OVMF_CODE" && -r "$OVMF_VARS" ]]; then
  BOOT_OPTS=( --boot loader="$OVMF_CODE",loader.readonly=yes,loader.type=pflash,nvram.template="$OVMF_VARS" )
  msg "Usando UEFI (OVMF)."
else
  warn "OVMF no encontrado. Instalá con: sudo apt install ovmf"
  warn "Se usará BIOS legado."
fi

# --- Crear VM ---
msg "Creando VM ${VM_NAME}..."
virt-install \
  --name "$VM_NAME" \
  --memory "$RAM_MB" --vcpus "$VCPUS" --cpu host-passthrough \
  --disk path="$DISK_PATH",format=qcow2,bus=virtio \
  --cdrom "$ISO_VM_PATH" \
  --network network=default,model=virtio \
  --graphics spice,gl=on \
  --video virtio \
  --sound ich9 \
  --rng /dev/urandom \
  --os-variant archlinux \
  "${BOOT_OPTS[@]}" \
  --noautoconsole || {
    err "Error al crear la VM. Revisá los permisos de libvirt o la ISO."
  }

msg "✅ VM creada correctamente."
msg "Abrí GNOME Boxes → Iniciá la VM 'arch-sway' → Boot desde la ISO de Arch."
msg "Dentro del live ISO ejecutá:"
echo
echo "    bash <(curl -fsSL https://raw.githubusercontent.com/dagorret/Arch-Sway/main/3_instalar_arch_auto.sh)"
echo
msg "Listo para continuar con la instalación automática."
