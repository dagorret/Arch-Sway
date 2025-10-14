#!/usr/bin/env bash
set -euo pipefail

# Crea una VM Arch Linux con libvirt/virt-install que GNOME Boxes detecta automáticamente.
# Requiere que hayas corrido antes el script 1 (stack KVM/OVMF).

VM_NAME="${VM_NAME:-arch-sway}"
ISO_DIR="${ISO_DIR:-$HOME/ISOs}"
VM_DIR="${VM_DIR:-$HOME/VMs}"
ISO_PATH="$ISO_DIR/archlinux-x86_64.iso"
SHA_FILE="$ISO_DIR/sha256sums.txt"
DISK_PATH="$VM_DIR/${VM_NAME}.qcow2"

DISK_SIZE_GB="${DISK_SIZE_GB:-20}"   # 20 GB dinámicos
RAM_MB="${RAM_MB:-4096}"             # 4 GB RAM
VCPUS="${VCPUS:-4}"                  # 4 vCPU

msg() { printf "\n\033[1;32m==>\033[0m %s\n" "$*"; }
err() { printf "\n\033[1;31mEE\033[0m %s\n" "$*"; exit 1; }

mkdir -p "$ISO_DIR" "$VM_DIR"

# --- Descargar ISO + checksums (desde mirror geo equivocado para ti por latencia) ---
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
  # Busca la línea de archlinux-x86_64.iso en sha256sums.txt y verifica
  if ! sha256sum -c --ignore-missing "sha256sums.txt"; then
    err "El checksum SHA256 NO coincide. Borra la ISO y reintenta (posible descarga corrupta)."
  fi
)
msg "Checksum OK."

# --- Crear disco qcow2 ---
msg "Creando disco qcow2 ${DISK_SIZE_GB}G en: $DISK_PATH"
qemu-img create -f qcow2 "$DISK_PATH" "${DISK_SIZE_GB}G"

# --- UEFI (OVMF) si está disponible ---
OVMF_CODE="/usr/share/OVMF/OVMF_CODE.fd"
OVMF_VARS="/usr/share/OVMF/OVMF_VARS.fd"
BOOT_OPTS=()
if [[ -r "$OVMF_CODE" && -r "$OVMF_VARS" ]]; then
  BOOT_OPTS=( --boot loader="$OVMF_CODE",loader.readonly=yes,loader.type=pflash,nvram.template="$OVMF_VARS" )
  msg "Usando UEFI (OVMF)."
else
  msg "OVMF no encontrado; se usará BIOS legado."
fi

# --- Crear VM ---
msg "Creando VM ${VM_NAME}..."
virt-install \
  --name "$VM_NAME" \
  --memory "$RAM_MB" --vcpus "$VCPUS" --cpu host-passthrough \
  --disk path="$DISK_PATH",format=qcow2,bus=virtio \
  --cdrom "$ISO_PATH" \
  --network network=default,model=virtio \
  --graphics spice,gl=on \
  --video virtio \
  --sound ich9 \
  --rng /dev/urandom \
  --os-variant archlinux \
  "${BOOT_OPTS[@]}" \
  --noautoconsole

msg "VM creada. Abrila desde GNOME Boxes como '${VM_NAME}'. Booteá desde la ISO y corré el script 3 dentro del Live."
