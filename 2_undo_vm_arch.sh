#!/usr/bin/env bash
set -euo pipefail

VM_NAME="${VM_NAME:-arch-sway}"
VM_STORAGE_DIR="/var/lib/libvirt/images"
DISK_PATH="${DISK_PATH:-${VM_STORAGE_DIR}/${VM_NAME}.qcow2}"
ISO_PATH_VM="${VM_STORAGE_DIR}/archlinux-x86_64.iso"

virsh --connect qemu:///system destroy "$VM_NAME" 2>/dev/null || true
virsh --connect qemu:///system undefine "$VM_NAME" --nvram 2>/dev/null \
  || virsh --connect qemu:///system undefine "$VM_NAME" 2>/dev/null || true

sudo rm -f -- "$DISK_PATH"
sudo rm -f -- "$ISO_PATH_VM"

echo "Reversión completa: VM eliminada y archivos borrados."
