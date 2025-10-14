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


