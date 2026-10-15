#!/bin/bash

# 1. Obtener el nombre de la distribución de forma robusta para cualquier distro
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO="${NAME:-Linux}"
else
    DISTRO=$(lsb_release -is 2>/dev/null || echo "Linux_Generic")
fi

# Limpiar espacios para usarlo como nombre de archivo seguro
DISTRO_CLEAN=$(echo "$DISTRO" | tr ' ' '_' | tr '[:upper:]' '[:lower:]')
FILENAME="${DISTRO_CLEAN}_registro.md"

# 2. Recolectar información detallada del sistema
CPU=$(lscpu 2>/dev/null | grep -E 'Model name|Nombre del modelo' | head -n 1 | cut -d: -f2 | sed 's/^[ \t]*//')
RAM=$(free -h 2>/dev/null | awk '/^Mem:/ {print $2}')
RAM_USADA=$(free -h 2>/dev/null | awk '/^Mem:/ {print $3 " usados de " $2}')
GPU=$(lspci 2>/dev/null | grep -iE "vga|3d|display" | head -n 1 | cut -d: -f3 | sed 's/^[ \t]*//')
HOSTNAME=$(hostname)
IP_PRIVADA=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7}' || hostname -I 2>/dev/null | awk '{print $1}' || echo "No detectada")
KERNEL=$(uname -r)
UPTIME=$(uptime -p 2>/dev/null || uptime | sed 's/.*up \([^,]*\),.*/\1/')

# 3. Verificar y obtener Fastfetch o Neofetch (forzando salida con --pipe false y limpiando colores ANSI)
FETCH_OUTPUT=""
if command -v fastfetch &> /dev/null; then
    FETCH_OUTPUT=$(fastfetch --pipe false 2>/dev/null | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g")
elif command -v neofetch &> /dev/null; then
    FETCH_OUTPUT=$(neofetch --stdout 2>/dev/null | sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,2})?)?[mGK]//g")
else
    echo "⚠️ [Aviso]: Ni 'fastfetch' ni 'neofetch' están instalados."
    FETCH_OUTPUT="⚠️ [Aviso]: 'fastfetch' o 'neofetch' no están instalados en este equipo.
Se recomienda instalarlo para ver este apartado gráfico:
- Debian / Ubuntu / Mint: sudo apt install fastfetch
- Fedora / RHEL: sudo dnf install fastfetch
- Arch Linux: sudo pacman -S fastfetch"
fi

# 4. Crear el archivo Markdown y escribir la estructura completa
cat << EOF > "$FILENAME"
# 🖥️ Registro de Equipo: $DISTRO

**Descripción/Ubicación en la sala:** [ESCRIBE AQUÍ QUÉ PC ES EN LA SALA]

---

## 🎨 Vista General del Sistema (Fetch)
\`\`\`text
$FETCH_OUTPUT
\`\`\`

## 💻 Información de Hardware
* **Procesador (CPU):** ${CPU:-No detectado}
* **Memoria RAM:** ${RAM_USADA:-$RAM}
* **Tarjeta Gráfica (GPU):** ${GPU:-No detectada}
* **Kernel de Linux:** $KERNEL

## 🌐 Red y Sistema
* **Nombre del Equipo (Hostname):** $HOSTNAME
* **Dirección IP Local:** $IP_PRIVADA
* **Tiempo de Actividad (Uptime):** $UPTIME

## 💽 Estado del Almacenamiento
\`\`\`text
$(df -h --total 2>/dev/null | grep -E "S.ficheros|Filesystem|total" || df -h)
\`\`\`

## 👥 Usuarios Humanos Registrados (UID >= 1000)
\`\`\`text
$(awk -F: '$3 >= 1000 && $3 != 65534 {printf "- %s (UID: %s, Shell: %s)\n", $1, $3, $7}' /etc/passwd 2>/dev/null)
\`\`\`

---
*📝 Registro generado automáticamente el $(date '+%d/%m/%Y a las %H:%M:%S')*
EOF

echo "✅ ¡Registro guardado con éxito en: $FILENAME!"
