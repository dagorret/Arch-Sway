#!/usr/bin/env bash
set -euo pipefail

# === Parámetros (podés modificar antes de correr) ===
DISK="${DISK:-/dev/vda}"          # Disco virtio en la VM creada
HOSTNAME="${HOSTNAME:-archvm}"
USER_NAME="${USER_NAME:-carlos}"  # Cambiá o dejá vacío para no crear usuario
USER_PWD="${USER_PWD:-changeme}"  # Se aplicará si USER_NAME != ""
ROOT_PWD="${ROOT_PWD:-root}"      # Cambiá luego con 'passwd'
LOCALE_GEN="${LOCALE_GEN:-es_AR.UTF-8 UTF-8}"
LANG_VAL="${LANG_VAL:-es_AR.UTF-8}"
TZ_VAL="${TZ_VAL:-America/Argentina/Cordoba}"

echo ">> Verificando modo UEFI..."
if [[ ! -d /sys/firmware/efi ]]; then
  echo "EE: No estás en modo UEFI. Reiniciá y asegurate de bootear la ISO en UEFI (OVMF)."
  exit 1
fi

echo ">> Sincronizando relojes..."
timedatectl set-ntp true

echo ">> Particionando ${DISK} (EFI 512MiB, Swap 2GiB, Root resto)..."
sgdisk --zap-all "${DISK}"
parted -s "${DISK}" mklabel gpt
parted -s "${DISK}" mkpart ESP fat32 1MiB 513MiB
parted -s "${DISK}" set 1 esp on
parted -s "${DISK}" mkpart swap linux-swap 513MiB 2561MiB
parted -s "${DISK}" mkpart root ext4 2561MiB 100%

EFI_PART="${DISK}1"
SWAP_PART="${DISK}2"
ROOT_PART="${DISK}3"

echo ">> Formateando y montando..."
mkfs.fat -F32 "${EFI_PART}"
mkswap "${SWAP_PART}"
mkfs.ext4 -F "${ROOT_PART}"

swapon "${SWAP_PART}"
mount "${ROOT_PART}" /mnt
mkdir -p /mnt/boot
mount "${EFI_PART}" /mnt/boot

echo ">> Instalando base del sistema..."
pacman -Sy --noconfirm
pacstrap -K /mnt base linux linux-firmware networkmanager vim sudo

echo ">> Generando fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

echo ">> Configuración chroot..."
arch-chroot /mnt /bin/bash <<CHROOT
set -euo pipefail

echo "${HOSTNAME}" > /etc/hostname
cat >/etc/hosts <<EOF
127.0.0.1   localhost
::1         localhost
127.0.1.1   ${HOSTNAME}.localdomain ${HOSTNAME}
EOF

# Zona horaria y reloj
ln -sf /usr/share/zoneinfo/${TZ_VAL} /etc/localtime
hwclock --systohc

# Locale
sed -i "s/^#${LOCALE_GEN}/${LOCALE_GEN}/" /etc/locale.gen || true
locale-gen
echo "LANG=${LANG_VAL}" > /etc/locale.conf

# Teclado de consola (opcional)
echo "KEYMAP=la-latin1" > /etc/vconsole.conf

# Habilitar red
systemctl enable NetworkManager

# Microcódigos + systemd-boot
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

echo ">> Instalación base completada."
echo ">> Desmontando y reiniciando..."
umount -R /mnt
swapoff "${SWAP_PART}" || true
echo ">> Podés 'reboot' ahora. Retirá la ISO del arranque en la VM."

