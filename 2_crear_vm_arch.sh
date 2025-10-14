#!/usr/bin/env bash
set -euo pipefail

VM_NAME="${VM_NAME:-arch-sway}"
ISO_DIR="${ISO_DIR:-$HOME/ISOs}"
VM_DIR="${VM_DIR:-$HOME/VMs}"
ISO_PATH="$ISO_DIR/archlinux-x86_64.iso"
DISK_PATH="$VM_DIR/${VM_NAME}.qcow2"
DISK_SIZE_GB="${DISK_SIZE_GB:-20}"     # 20 GB dinámicos
RAM_MB="${RAM_MB:-4096}"               # 4 GB RAM
VCPUS="${VCPUS:-4}"                    # 4 vCPU

mkdir -p "$ISO_DIR" "$VM_DIR"

echo ">> Descargando ISO de Arch Linux (si no existe)..."
if [[ ! -f "$ISO_PATH" ]]; then
  # Elegimos un mirror confiable
  curl -L -o "$ISO_PATH" https://geo.mirror.pkgbuild.com/iso/latest/archlinux-x86_64.iso
fi

echo ">> Creando disco qcow2 de ${DISK_SIZE_GB}G en: $DISK_PATH"
qemu-img create -f qcow2 "$DISK_PATH" "${DISK_SIZE_GB}G"

# Detectar rutas OVMF (UEFI). En Ubuntu suelen ser estas:
OVMF_CODE="/usr/share/OVMF/OVMF_CODE.fd"
OVMF_VARS="/usr/share/OVMF/OVMF_VARS.fd"
BOOT_OPTS=()
if [[ -r "$OVMF_CODE" && -r "$OVMF_VARS" ]]; then
  BOOT_OPTS=( --boot loader="$OVMF_CODE",loader.readonly=yes,loader.type=pflash,nvram.template="$OVMF_VARS" )
  echo ">> Usando UEFI (OVMF)."
else
  echo "!! OVMF no encontrado; se usará BIOS legado."
fi

echo ">> Creando VM ${VM_NAME} (esto abrirá una ventana de consola gráfica si está disponible)..."
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

echo
echo ">> VM creada. Abrila desde GNOME Boxes (aparece como '${VM_NAME}')."
echo "   Booteá desde la ISO y, dentro del Live de Arch, ejecutá el script #3 para instalar automáticamente."

