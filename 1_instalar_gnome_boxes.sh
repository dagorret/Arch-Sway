#!/usr/bin/env bash
set -euo pipefail

# Instala Boxes y el stack KVM/QEMU/libvirt + UEFI (OVMF)
sudo apt update
sudo apt install -y \
  gnome-boxes qemu-system libvirt-daemon-system libvirt-clients virt-manager \
  ovmf bridge-utils spice-vdagent

# Agrega tu usuario a los grupos necesarios
sudo usermod -aG libvirt,kvm "$USER"

echo
echo ">> Listo. Cerrá sesión y volvé a entrar (o reiniciá) para aplicar pertenencia a grupos."
echo "   Luego podés abrir 'GNOME Boxes' desde el menú."

