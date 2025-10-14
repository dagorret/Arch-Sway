#!/usr/bin/env bash
set -euo pipefail

# Ejecutar dentro del Live ISO de Arch (TTY). Instala en /dev/vda:
# - GPT: EFI 512MiB (FAT32), SWAP 2GiB, ROOT ext4 resto.
# - systemd-boot (UEFI), locale es_AR.UTF-8, zona horaria America/Argentina/Cordoba, NetworkManager.
# - Usa reflector para mirrors rápidos (AR/BR/CL) antes de pacstrap.

# ===== Parámetros editables =====
DISK="${DISK:-/dev/vda}"
HOSTNAME="${HOSTNAME:-archvm}"
USER_NAME="${USER_NAME:-carlos}"     # vacío para no crear usuario
USER_PWD="${USER_PWD:-changeme}"     # usado si USER_NAME != ""
ROOT_PWD="${ROOT_PWD:-root}"
LOCALE_GEN="${LOCALE_GEN:-es_AR.UTF-8 UTF-8}"
LANG_VAL="${LANG_VAL:-es_AR.UTF-8}"
TZ_VAL="${TZ_VAL:-America/Argentina/Cordoba}"

msg() { printf "\n\033[1;32m==>\033[0m %s\n" "$*"; }
err() { printf "\n\033[1;31mEE\033[0m %s\n" "$*"; exit 1; }

# --- Checks previos ---
[[ -d /sys/firmware/efi ]] || err "No estás en modo UEFI. Booteá la ISO como UEFI (OVMF) y reintentá."
ping -c1 -W2 archlinux.org >/dev/null 2>&1 || err "Sin red. Configurá red (ip link / iwctl) y reintentá."

msg "Sincronizando relojes..."
timedatectl set-ntp true

# --- Particionado y formateo ---
msg "Particionando ${DISK} (EFI 512MiB, Swap 2GiB, Root resto)..."
sgdisk --zap-all "${DISK}"
parted -s "${DISK}" mklabel gpt
parted -s "${DISK}" mkpart ESP fat32 1MiB 513MiB
parted -s "${DISK}" set 1 esp on
parted -s "${DISK}" mkpart swap linux-swap 513MiB 2561MiB
parted -s "${DISK}" mkpart root ext4 2561MiB 100%

EFI_PART="${DISK}1"
SWAP_PART="${DISK}2"
ROOT_PART="${DISK}3"

msg "Formateando y montando..."
mkfs.fat -F32 "${EFI_PART}"
mkswap "${SWAP_PART}"
mkfs.ext4 -F "${ROOT_PART}"

swapon "${SWAP_PART}"
mount "${ROOT_PART}" /mnt
mkdir -p /mnt/boot
mount "${EFI_PART}" /mnt/boot

# --- Mirrors rápidos (AR/BR/CL) con reflector ---
msg "Actualizando mirrors con reflector (AR/BR/CL)..."
pacman -Sy --noconfirm reflector
reflector --country 'Argentina,Brazil,Chile' --age 48 --protocol https \
          --sort rate --save /etc/pacman.d/mirrorlist

# --- Instalación base ---
msg "Instalando base del sistema..."
pacstrap -K /mnt base linux linux-firmware networkmanager vim sudo

msg "Generando fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

# --- Configuración dentro del chroot ---
msg "Configurando sistema base..."
arch-chroot /mnt /bin/bash <<CHROOT
set -euo pipefail

echo "${HOSTNAME}" > /etc/hostname
cat >/etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${HOSTNAME}.localdomain ${HOSTNAME}
EOF

ln -sf /usr/share/zoneinfo/${TZ_VAL} /etc/localtime
hwclock --systohc

sed -i "s/^#${LOCALE_GEN}/${LOCALE_GEN}/" /etc/locale.gen || true
locale-gen
echo "LANG=${LANG_VAL}" > /etc/locale.conf
echo "KEYMAP=la-latin1" > /etc/vconsole.conf

systemctl enable NetworkManager

# Microcódigo Intel + systemd-boot
pacman -S --noconfirm intel-ucode
bootctl install

ROOT_UUID=\$(blkid -s PARTUUID -o value ${ROOT_PART})

cat >/boot/loader/loader.conf <<EOF
default arch
timeout 3
editor no
EOF

cat >/boot/loader/entries/arch.conf <<EOF
title   Arch Linux
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /initramfs-linux.img
options root=PARTUUID=\${ROOT_UUID} rw
EOF

# Usuarios y contraseñas
echo "root:${ROOT_PWD}" | chpasswd
if [[ -n "${USER_NAME}" ]]; then
  useradd -m -G wheel -s /bin/bash "${USER_NAME}"
  echo "${USER_NAME}:${USER_PWD}" | chpasswd
  sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
fi
CHROOT

msg "Desmontando y finalizando..."
umount -R /mnt
swapoff "${SWAP_PART}" || true

msg "Instalación completa. Ejecutá:  reboot"
echo "Recordá quitar/expulsar la ISO en GNOME Boxes para bootear desde disco."
