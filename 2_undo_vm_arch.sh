#!/usr/bin/env bash
set -euo pipefail

# 2_undo_vm_arch.sh
# Deshace los efectos del script 2 "corregido":
# - Apaga y elimina la VM 'arch-sway' (si existe)
# - Borra el disco qcow2 en /var/lib/libvirt/images
# - Borra la ISO COPIADA a /var/lib/libvirt/images (no toca tu ISO en ~/ISOs)
# - NO toca la red "default" de libvirt ni otros recursos

VM_NAME="${VM_NAME:-arch-sway}"
VM_STORAGE_DIR="/var/lib/libvirt/images"
DISK_PATH="${DISK_PATH:-${VM_STORAGE_DIR}/${VM_NAME}.qcow2}"
ISO_BASENAME="archlinux-x86_64.iso"
ISO_PATH_VM="${VM_STORAGE_DIR}/${ISO_BASENAME}"

msg() { printf "\n\033[1;32m==>\033[0m %s\n" "$*"; }
warn() { printf "\n\033[1;33m!!\033[0m %s\n" "$*"; }
err() { printf "\n\033[1;31mEE\033[0m %s\n" "$*"; exit 1; }

need() { command -v "$1" >/dev/null 2>&1 || err "Falta comando: $1"; }
need virsh
need sudo

# 1) Apagar la VM si está corriendo
if virsh --connect qemu:///system domstate "$VM_NAME" &>/dev/null; then
  STATE=$(virsh --connect qemu:///system domstate "$VM_NAME" 2>/dev/null || true)
  if [[ "$STATE" == "running" || "$STATE" == "paused" ]]; then
    msg "Apagando VM $VM_NAME ..."
    virsh --connect qemu:///system destroy "$VM_NAME" || true
  fi

  # 2) Undefine (eliminar definición)
  msg "Eliminando definición de VM $VM_NAME ..."
  # Quitar también posibles NVRAM si fue UEFI
  virsh --connect qemu:///system undefine "$VM_NAME" --nvram || \
  virsh --connect qemu:///system undefine "$VM_NAME" || true
else
  warn "La VM '$VM_NAME' no existe en libvirt (omitido)."
fi

# 3) Borrar disco qcow2
if [[ -f "$DISK_PATH" ]]; then
  msg "Borrando disco: $DISK_PATH"
  sudo rm -f -- "$DISK_PATH"
else
  warn "No se encontró disco en $DISK_PATH (omitido)."
fi

# 4) Borrar ISO copiada al storage de libvirt
if [[ -f "$ISO_PATH_VM" ]]; then
  msg "Borrando ISO copiada en: $ISO_PATH_VM"
  sudo rm -f -- "$ISO_PATH_VM"
else
  warn "No se encontró ISO copiada en $ISO_PATH_VM (omitido)."
fi

msg "Hecho. Entorno revertido a estado previo a la creación con el script 2 corregido."
echo "Nota: Tu ISO original en ~/ISOs NO se tocó."
