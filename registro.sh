#!/bin/bash

# 1. Obtener el nombre de la distribución
DISTRO=$(lsb_release -is 2>/dev/null || grep -oP '(?<=^NAME=).*' /etc/os-release | tr -d '"' | awk '{print $1}')
[ -z "$DISTRO" ] && DISTRO="Linux_Generic"

# 2. Definir el nombre del archivo Markdown
FILENAME="${DISTRO}_registro.md"

# 3. Recolectar información del sistema
CPU=$(lscpu | grep -E 'Nombre del modelo|Model name' | cut -d: -f2 | sed 's/^[ \t]*//')
RAM=$(free -h | awk '/^Mem:/ {print $2}')
GPU=$(lspci | grep -E "VGA|3D" | cut -d: -f3 | sed 's/^[ \t]*//')
HOSTNAME=$(hostname)
IP_PRIVADA=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7}' || hostname -i | awk '{print $1}')

# 4. Crear el archivo Markdown y escribir la estructura
cat << EOF > "$FILENAME"
# Registro de Equipo: $DISTRO

**Descripción/Ubicación en la sala:** [ESCRIBE AQUÍ QUÉ PC ES EN LA SALA]

---

## 💻 Información de Hardware
* **Procesador (CPU):** ${CPU:-No detectado}
* **Memoria RAM:** $RAM
* **Tarjeta Gráfica (GPU):** ${GPU:-No detectada}

## 🌐 Red y Sistema
* **Nombre del Equipo (Hostname):** $HOSTNAME
* **Dirección IP Local:** $IP_PRIVADA

## 💽 Estado del Almacenamiento
\`\`\`text
$(df -h --total | grep -E "S.ficheros|Filesystem|total")
\`\`\`

## 👥 Usuarios Humanos Registrados
\`\`\`text
$(awk -F: '$3 >= 1000 && $3 != 65534 {printf "- %s (UID: %s)\n", $1, $3}' /etc/passwd)
\`\`\`

---
*Registro generado automáticamente el $(date '+%d/%m/%Y a las %H:%M:%S')*
EOF

echo "✅ Registro guardado con éxito en: $FILENAME"

