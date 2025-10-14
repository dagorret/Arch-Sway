# Arch-Sway
Actualizado al 2025


Ejecuta la secuenta.

Parametros

Ubuntu 24.04
Gnome Boxes para VM
ARch linux: 4Gb, 20 Disco, 2 swap.
Emacs y pandoc.
Sway


## ⚡ Instalación directa (sin clonar el repo)

Podés ejecutar cada etapa directamente desde el terminal usando `curl | bash`.  
> ⚠️ Solo usá esto si confiás en el origen del script (este repositorio).  
> Los comandos descargan y ejecutan los scripts directamente desde GitHub.

| Etapa | Descripción | Comando |
|--------|--------------|---------|
| 🧰 **1. Instalar GNOME Boxes** (host Ubuntu) | Instala `gnome-boxes`, KVM, QEMU, libvirt y dependencias. | ```bash<br>bash <(curl -fsSL https://raw.githubusercontent.com/dagorret/Arch-Sway/main/1_instalar_gnome_boxes.sh)<br>``` |
| 💽 **2. Crear la VM Arch Linux** (host Ubuntu) | Descarga ISO, verifica checksum y crea la VM con 4 GB RAM y 20 GB dinámicos. | ```bash<br>bash <(curl -fsSL https://raw.githubusercontent.com/dagorret/Arch-Sway/main/2_crear_vm_arch.sh)<br>``` |
| ⚙️ **3. Instalar Arch automáticamente** (dentro del Live ISO) | Crea particiones EFI/Swap/Root, instala Arch y configura idioma/esquema argentino. | ```bash<br>bash <(curl -fsSL https://raw.githubusercontent.com/dagorret/Arch-Sway/main/3_instalar_arch_auto.sh)<br>``` |
| 🧩 **4. Configurar Sway y entorno completo** (dentro de Arch instalado) | Instala Sway, Waybar, Wofi, Emacs, MarkText, Pandoc + TeX Live full, temas y utilidades. | ```bash<br>bash <(curl -fsSL https://raw.githubusercontent.com/dagorret/Arch-Sway/main/4_postinstall_sway.sh)<br>``` |

---

### 💡 Instalación completa en un solo comando

Si querés automatizar todo el proceso (detectar host o VM, instalar GNOME Boxes, crear VM y luego ejecutar los scripts dentro), podés usar:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/dagorret/Arch-Sway/main/install_all.sh)
```

### Requsitos

| Recurso        | Mínimo                  | Recomendado |
| -------------- | ----------------------- | ----------- |
| CPU            | 2 núcleos               | 4 núcleos   |
| RAM            | 3 GB                    | 4 GB        |
| Disco virtual  | 20 GB                   | 30 GB       |
| Virtualización | VT-x / AMD-V activado   |             |
| Aceleración 3D | Activada en GNOME Boxes |             |

