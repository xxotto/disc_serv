#!/bin/bash

# Función para mostrar uso del script
usage() {
    echo "Uso: $0 -c <campaña> -d <fecha> -b <tamaño_lote> -r <grabaciones>"
    echo "  -c <campaña>     ID de campaña a utilizar (ejm. Anx5010)"
    echo "  -d <fecha>       Fecha en formato YYYY-MM-DD"
    echo "  -b <batch_size>  Cantidad máxima de archivos a enviar por lote"
    echo "  -r <grabaciones> Lista de grabaciones locales a subir (separadas por comas)"
    exit 1
}

# Leer los argumentos del script
while getopts ":c:d:b:r:" opt; do
    case ${opt} in
        c ) campaign=$OPTARG ;;
        d ) date=$OPTARG ;;
        b ) batch_size=$OPTARG ;;
        r ) recordings=$OPTARG ;;
        \? ) usage ;;
    esac
done
shift $((OPTIND -1))

# Verificar que todos los parámetros requeridos están presentes
if [ -z "${campaign}" ] || [ -z "${date}" ] || [ -z "${batch_size}" ] || [ -z "${recordings}" ]; then
    usage
fi

# Extraer año, mes y día de la fecha
year=$(echo $date | cut -d'-' -f1)
month=$(echo $date | cut -d'-' -f2)
day=$(echo $date | cut -d'-' -f3)

# Convertir los resultados a un array
IFS=$'\n' read -rd '' -a files <<<"$recordings"

# Cargar el archivo de configuración
source source /opt/disc_serv/env/sftp_env.sh

echo "Enviando grabaciones de la campaña $campaign para la fecha $date al server remoto..."

# Enviar archivos en lotes usando SFTP
for (( i=0; i<${#files[@]}; i+=batch_size )); do
    batch=("${files[@]:i:batch_size}")
    #echo "Enviando lote de archivos: ${batch[@]}"
    
    # Crear una variable con los comandos SFTP
    sftp_commands=""
    for file in "${batch[@]}"; do
        remote_path="$campaign/$year/$month/$day/$(basename $file)"
        #echo "Subiendo $file $remote_path"
        sftp_commands+="put $file $remote_path"$'\n'
    done
    
    # Ejecutar el comando SFTP usando la variable
    echo -e "$sftp_commands" | sshpass \
        -p "$SFTP_PASS" sftp \
        -oBatchMode=no \
        -o ServerAliveInterval=30 \
        -o ServerAliveCountMax=20 "$SFTP_USER@$SFTP_HOST" \
        > /dev/null 2>&1
done

echo "Envios terminados."
