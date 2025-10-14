#!/usr/bin/env bash
set -euo pipefail

# 2_undo_vm_arch.sh
# Limpia la VM creada por el Paso 2 (virt-install) sin dejar rastros.
#
# - Apaga y elimina la VM (session y/o system)
# - Borra el disco qcow2
# - Borra la ISO copiada al storage de libvirt
# - Intenta limpiar NVRAM
#
# Variables opcionales:
#   VM_NAME         (default: arch-sway)
#   LIBVIRT_SCOPE   (session|system|auto) default: auto
#
# Uso:
#   chmod +x 2_undo_vm_arch.sh
#   ./2_undo_vm_arch.sh
#
#   # Forzar un alcance:
#   LIBVIRT_SCOPE=session ./2_undo_vm_arch.sh
#   LIBVIRT_SCOPE=system  ./2_undo_vm_arch.sh

# -------- Parámetros --------
VM_NAME="${VM_NAME:-arch-sway}"
LIBVIRT_SCOPE="${LIBVIRT_SCOPE:-auto}"

# Rutas de storages
SESSION_IMG_DIR="$HOME/.local/share/libvirt/images"
SYSTEM_IMG_DIR="/var/lib/libvirt/images"

# ISO copiada por el script 2
ISO_BASENAME="archlinux-x86_64.iso"

# NVRAM (UEFI) posibles ubicaciones
SESSION_NVRAM_DIR="$HOME/.config/libvirt/qemu/nvram"
SYSTEM_NVRAM_DIR="/var/lib/libvirt/qemu/nvram"

msg()  { printf "\n\033[1;32m==>\033[0m %s\n" "$*"; }
warn() { printf "\n\033[1;33m!!\033[0m %s\n" "$*"; }
err()  { printf "\n\033[1;31mEE\033[0m %s\n" "$*"; exit 1; }

need() { command -v "$1" >/dev/null 2>&1 || err "Falta comando: $1"; }
need virsh

# -------- Helpers --------
vm_exists() {
  local uri="$1"
  virsh --connect "$uri" dominfo "$VM_NAME" &>/dev/null
}

vm_state() {
  local uri="$1"
  virsh --connect "$uri" domstate "$VM_NAME" 2>/dev/null || echo "unknown"
}

destroy_vm() {
  local uri="$1"
  if vm_exists "$uri"; then
    local st
    st="$(vm_state "$uri")"
    if [[ "$st" == "running" || "$st" == "paused" || "$st" == "pmsuspended" ]]; then
      msg "Apagando VM '$VM_NAME' en $uri ..."
      virsh --connect "$uri" destroy "$VM_NAME" || true
    fi
  fi
}

undefine_vm() {
  local uri="$1"
  if vm_exists "$uri"; then
    msg "Eliminando definición de VM '$VM_NAME' en $uri ..."
    # Intentar con --nvram (UEFI); si falla, sin flag
    virsh --connect "$uri" undefine "$VM_NAME" --nvram 2>/dev/null \
      || virsh --connect "$uri" undefine "$VM_NAME" 2>/dev/null \
      || true
  else
    warn "VM '$VM_NAME' no encontrada en $uri (omitido)."
  fi
}

rm_file_safe() {
  local f="$1"
  if [[ -f "$f" ]]; then
    msg "Borrando: $f"
    rm -f -- "$f" 2>/dev/null || sudo rm -f -- "$f" 2>/dev/null || true
  fi
}

cleanup_storage() {
  local scope="$1"
  local img_dir iso_path qcow2_path

  if [[ "$scope" == "session" ]]; then
    img_dir="$SESSION_IMG_DIR"
  else
    img_dir="$SYSTEM_IMG_DIR"
  fi

  qcow2_path="$img_dir/${VM_NAME}.qcow2"
  iso_path="$img_dir/${ISO_BASENAME}"

  if [[ -f "$qcow2_path" ]]; then
    msg "Eliminando disco qcow2 ($scope): $qcow2_path"
    rm -f "$qcow2_path" 2>/dev/null || sudo rm -f "$qcow2_path" 2>/dev/null || true
  else
    warn "No se encontró disco qcow2 en $qcow2_path ($scope)."
  fi

  if [[ -f "$iso_path" ]]; then
    msg "Eliminando ISO copiada ($scope): $iso_path"
    rm -f "$iso_path" 2>/dev/null || sudo rm -f "$iso_path" 2>/dev/null || true
  else
    warn "No se encontró ISO copiada en $iso_path ($scope)."
  fi
}

cleanup_nvram() {
  local scope="$1"
  local dir
  if [[ "$scope" == "session" ]]; then
    dir="$SESSION_NVRAM_DIR"
  else
    dir="$SYSTEM_NVRAM_DIR"
  fi

  # Archivos NVRAM típicos: <name>_VARS.fd o similares
  if [[ -d "$dir" ]]; then
    # Buscar entradas relacionadas al nombre de la VM
    shopt -s nullglob
    local matches=("$dir/${VM_NAME}"*.fd "$dir/${VM_NAME}"*.var*)
    for f in "${matches[@]}"; do
      [[ -e "$f" ]] || continue
      msg "Eliminando NVRAM ($scope): $f"
      rm -f "$f" 2>/dev/null || sudo rm -f "$f" 2>/dev/null || true
    done
    shopt -u nullglob
  fi
}

do_scope() {
  local uri="$1"   # qemu:///session | qemu:///system
  local scope="$2" # session | system

  msg "Procesando '$VM_NAME' en $uri ..."
  destroy_vm "$uri"
  undefine_vm "$uri"
  cleanup_storage "$scope"
  cleanup_nvram "$scope"
}

# -------- Lógica principal --------
case "$LIBVIRT_SCOPE" in
  session)
    do_scope "qemu:///session" "session"
    ;;
  system)
    do_scope "qemu:///system" "system"
    ;;
  auto)
    # Intentar ambos: primero system, luego session
    do_scope "qemu:///system" "system"
    do_scope "qemu:///session" "session"
    ;;
  *)
    err "LIBVIRT_SCOPE inválido: $LIBVIRT_SCOPE (use: session|system|auto)"
    ;;
esac

msg "✅ Reversión completa: VM, disco, ISO copiada y NVRAM (si existía) eliminados."
echo "Nota: tu ISO original en \$HOME/ISOs no fue modificada."
