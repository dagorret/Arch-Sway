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
| 🧰 **1. Instalar GNOME Boxes** (host Ubuntu) | Instala `gnome-boxes`, KVM, QEMU, libvirt y dependencias. | ```bash <(curl -fsSL https://raw.githubusercontent.com/dagorret/Arch-Sway/main/1_instalar_gnome_boxes.sh)``` |
| 💽 **2. Crear la VM Arch Linux** (host Ubuntu) | Descarga ISO, verifica checksum y crea la VM con 4 GB RAM y 20 GB dinámicos. | ```bash <(curl -fsSL https://raw.githubusercontent.com/dagorret/Arch-Sway/main/2_crear_vm_arch.sh)``` |
| ⚙️ **3. Instalar Arch automáticamente** (dentro del Live ISO) | Crea particiones EFI/Swap/Root, instala Arch y configura idioma/esquema argentino. | ```bash <(curl -fsSL https://raw.githubusercontent.com/dagorret/Arch-Sway/main/3_instalar_arch_auto.sh)``` |
| 🧩 **4. Configurar Sway y entorno completo** (dentro de Arch instalado) | Instala Sway, Waybar, Wofi, Emacs, MarkText, Pandoc + TeX Live full, temas y utilidades. | ```bash <(curl -fsSL https://raw.githubusercontent.com/dagorret/Arch-Sway/main/4_postinstall_sway.sh)```  Short url: https://h1.nu/arch-sway O.... Crea manualmente|

---
### Crear VM manualmente

OPCIÓN 1 — GNOME Boxes (gráfico, simple)

Abrí GNOME Boxes → Nueva caja (+).

Elegí Archivo ISO → seleccioná tu archlinux-x86_64.iso (en ~/ISOs).

En “Personalizar” (abajo a la izquierda):

Memoria: 4096 MB

Disco: 20 GB (dinámico)

Procesadores: 4 núcleos

Marcá “Habilitar UEFI” si aparece.

Finalizá.
Boxes creará una VM en tu entorno de usuario (qemu:///session) con red SLIRP (funciona sin configuración).

---
### 💡 Instalación completa en un solo comando

Si querés automatizar todo el proceso (detectar host o VM, instalar GNOME Boxes, crear VM y luego ejecutar los scripts dentro), podés usar:

```bash
bash <(curl -fsSL https:/ /raw.githubusercontent.com/dagorret/Arch-Sway/main/install_all.sh)
```

### Requsitos

| Recurso        | Mínimo                  | Recomendado |
| -------------- | ----------------------- | ----------- |
| CPU            | 2 núcleos               | 4 núcleos   |
| RAM            | 3 GB                    | 4 GB        |
| Disco virtual  | 20 GB                   | 30 GB       |
| Virtualización | VT-x / AMD-V activado   |             |
| Aceleración 3D | Activada en GNOME Boxes |             |

### 🪶 Iniciar entorno gráfico

Una vez instalado y configurado, iniciar sesión en Arch y ejecutar:

```
sway-start
```

## 🧠 Instalación automática completa (`install_all.sh`)

El script `install_all.sh` detecta automáticamente el entorno donde se ejecuta y lanza el paso correspondiente del proceso:

- 🧰 **Ubuntu Host** → Instala GNOME Boxes y crea la VM de Arch.  
- 💽 **Live ISO de Arch** → Ejecuta la instalación automática del sistema.  
- 🧩 **Arch instalado** → Configura Sway, Emacs, MarkText, Pandoc, temas y entorno completo.

### ▶️ Ejecución directa

Podés correrlo sin clonar el repositorio:

bash <(curl -fsSL https://raw.githubusercontent.com/dagorret/Arch-Sway/main/install_all.sh)

El script determina si estás en el **host**, el **live ISO**, o el **sistema instalado**, y actúa en consecuencia.  
También verifica que `curl` esté disponible e instala dependencias mínimas según el caso.

### ⚙️ Variable `RAW_BASE` (opcional)

Podés usar la variable de entorno `RAW_BASE` para apuntar a otra rama, fork o versión del repositorio.  
Esto permite testear scripts sin modificar el `main`.

**Ejemplo:**

RAW_BASE="https://raw.githubusercontent.com/dagorret/Arch-Sway/dev" \
bash <(curl -fsSL https://raw.githubusercontent.com/dagorret/Arch-Sway/main/install_all.sh)

En este ejemplo:
- El script `install_all.sh` se descarga de la rama `main`.
- Todos los demás (`1_…`, `2_…`, `3_…`, `4_…`) se ejecutan desde la rama `dev`.

### 🔍 Detección automática

El script identifica el entorno usando `/etc/os-release` y `/run/archiso`:

| Entorno detectado | Acción ejecutada |
|--------------------|------------------|
| `ubuntu_host` | Ejecuta `1_instalar_gnome_boxes.sh` y `2_crear_vm_arch.sh` |
| `arch_live` | Ejecuta `3_instalar_arch_auto.sh` |
| `arch_installed` | Ejecuta `4_postinstall_sway.sh` |
| `unknown` | Aborta con advertencia y muestra instrucciones manuales |

### 💡 Ejemplo de flujo completo

# Ejecutar en Ubuntu (host)
bash <(curl -fsSL https://raw.githubusercontent.com/dagorret/Arch-Sway/main/install_all.sh)

# Dentro del Live ISO (automático)
bash <(curl -fsSL https://raw.githubusercontent.com/dagorret/Arch-Sway/main/install_all.sh)

# En Arch recién instalado
bash <(curl -fsSL https://raw.githubusercontent.com/dagorret/Arch-Sway/main/install_all.sh)

### 🪶 Iniciar entorno gráfico tras la instalación

sway-start

El script incluye fallback automático (`WLR_RENDERER_ALLOW_SOFTWARE=1`) si la VM no dispone de aceleración 3D.


## ♻️ Revertir la creación de la máquina virtual (Undo Paso 2)

Si necesitás eliminar la VM creada por el **Paso 2**, podés hacerlo de dos formas:  
manualmente desde la terminal o usando el script `2_undo_vm_arch.sh`.

---

### 🔧 Opción 1 — Comandos directos (modo seguro)

Ejecutá estos comandos en tu **Ubuntu host**:

```bash
virsh --connect qemu:///system destroy arch-sway 2>/dev/null || true
virsh --connect qemu:///system undefine arch-sway --nvram 2>/dev/null \
  || virsh --connect qemu:///system undefine arch-sway 2>/dev/null || true
sudo rm -f /var/lib/libvirt/images/arch-sway.qcow2
sudo rm -f /var/lib/libvirt/images/archlinux-x86_64.iso
echo "✅ Entorno revertido: VM y archivos eliminados."
```

🧩 **Qué hace:**
- Apaga la VM `arch-sway` si está corriendo.  
- Elimina su definición del gestor libvirt.  
- Borra el disco virtual (`arch-sway.qcow2`).  
- Elimina la copia de la ISO en `/var/lib/libvirt/images/`.  
> La ISO original en `~/ISOs/` no se toca.

---

### ⚙️ Opción 2 — Usando el script `2_undo_vm_arch.sh`

Si ya tenés el script de reversión en tu repositorio:

```bash
chmod +x 2_undo_vm_arch.sh
./2_undo_vm_arch.sh
```

🔸 El script incluye validaciones, mensajes informativos y puede usarse tanto en entornos `system` como `session`.

---

### 💡 Nota para VMs creadas en modo *session* (Boxes)

Si la VM fue creada con el nuevo **script 2** (por defecto en modo `session`),  
cambiá las conexiones de libvirt a `qemu:///session` en los comandos:

```bash
virsh --connect qemu:///session destroy arch-sway 2>/dev/null || true
virsh --connect qemu:///session undefine arch-sway 2>/dev/null || true
```

Esto elimina la VM directamente desde el entorno de usuario  
(el mismo que usa **GNOME Boxes**) sin requerir privilegios de root.

---

✅ **Resultado esperado:**
```
Entorno revertido: VM y archivos eliminados.
```

Tu sistema quedará exactamente como antes del Paso 2.


### Borrar VM “huérfana” en qemu:///session y el disco

```
# Ver qué hay en session
virsh --connect qemu:///session list --all

# Apagar si estuviera corriendo (no suele estar)
virsh --connect qemu:///session destroy arch-sway 2>/dev/null || true

# Eliminar la definición (y NVRAM si existiera)
virsh --connect qemu:///session undefine arch-sway --nvram 2>/dev/null \
  || virsh --connect qemu:///session undefine arch-sway 2>/dev/null || true

# Borrar el disco que quedó ocupado
rm -f ~/.local/share/libvirt/images/arch-sway.qcow2
```
Y yapa

```
virsh --connect qemu:///system list --all
```

### Chequea el paquete, que exista

```
sudo apt update
sudo apt install -y ovmf
```

Volvé a crear la VM

```
LIBVIRT_SCOPE=session bash 2_crear_vm_arch.sh
```
