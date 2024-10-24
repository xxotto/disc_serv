#!/bin/bash

# Mostrar uso del script
usage() {
    echo "Uso: $0 -c <campaña> -d <fecha>"
    echo "  -c <campaña>   ID de campaña a utilizar (ejm. Anx5010)"
    echo "  -d <fecha>    Fecha en formato YYYY-MM-DD"
    exit 1
}

# Verificar si se proporcionaron argumentos
if [ $# -eq 0 ]; then
    usage
fi

# Parsear argumentos
while getopts "c:d:" opt; do
    case $opt in
        c) campaign=$OPTARG ;;
        d) date=$OPTARG ;;
        *) usage ;;
    esac
done

# Verificar si se proporcionaron ambos argumentos
if [ -z "$campaign" ] || [ -z "$date" ]; then
    usage
fi

# Cargar el archivo de configuración
source source /opt/disc_serv/env/sftp_env.sh

# Obtener el año, mes y día de la fecha proporcionada
year=$(echo $date | cut -d'-' -f1)
month=$(echo $date | cut -d'-' -f2)
day=$(echo $date | cut -d'-' -f3)

# Definir los comandos a ejecutar en el servidor remoto
COMMANDS=$(cat <<EOF
mkdir $campaign
cd $campaign
mkdir $year
cd $year
mkdir $month
cd $month
mkdir $day
EOF
)

echo "Creando directorio $campaign/$year/$month/$day en server remoto..."

# Conectar y ejecutar los comandos usando sshpass y sftp, redirigiendo la salida a /dev/null
sshpass -p "$SFTP_PASS" sftp \
        -o BatchMode=no \
        -o StrictHostKeyChecking=no \
        "$SFTP_USER@$SFTP_HOST" <<EOF > /dev/null 2>&1
$COMMANDS
EOF
