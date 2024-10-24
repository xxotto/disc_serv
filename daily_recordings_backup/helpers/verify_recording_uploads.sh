#!/bin/bash

# Mostrar mensaje de uso
usage() {
    echo "Uso: $0 -c <campaña> -d <fecha>"
    echo "Ejemplo: $0 -c Anx5010 -d 2024-07-30"
    exit 1
}

# Verificar si no se proporcionaron argumentos
if [ $# -eq 0 ]; then
    usage
fi

# Procesar argumentos
while getopts "c:d:" opt; do
    case $opt in
        c) campaign=$OPTARG ;;
        d) date=$OPTARG ;;
        *) usage ;;
    esac
done

# Verificar si los argumentos obligatorios están presentes
if [ -z "$campaign" ] || [ -z "$date" ]; then
    usage
fi

# Cargar el archivo de configuración
source /opt/disc_serv/env/sftp_env.sh
echo "Verificando archivos de la campaña $campaign para la fecha $date en el SFTP..."
DIRECTORY="/var/spool/asterisk/monitorDONE/MP3"

# Obtener el año, mes y día de la fecha proporcionada
year=$(echo $date | cut -d'-' -f1)
month=$(echo $date | cut -d'-' -f2)
day=$(echo $date | cut -d'-' -f3)

# Definir los comandos a ejecutar en el servidor remoto
COMMANDS=$(cat <<EOF
ls $campaign/$year/$month/$day
EOF
)

# Conectar y ejecutar los comandos usando sshpass y sftp, capturando la salida en una variable
SFTP_OUTPUT=$(sshpass -p "$SFTP_PASS" sftp \
        -o BatchMode=no \
        -o StrictHostKeyChecking=no \
        "$SFTP_USER@$SFTP_HOST" <<EOF
$COMMANDS
EOF
)

sftp_files=$(echo "$SFTP_OUTPUT" | grep .mp3 | awk -F'/' '{print $NF}')
local_files=$(/opt/disc_serv/daily_recordings_backup/helpers/find_recordings.sh -c $campaign -d $date | awk -F'/' '{print $NF}')

# Convertir las listas de archivos en arrays
IFS=$'\n' read -d '' -r -a sftp_array <<< "$sftp_files"
IFS=$'\n' read -d '' -r -a local_array <<< "$local_files"

# Contar el número de elementos en los arrays
sftp_count=${#sftp_array[@]}
local_count=${#local_array[@]}

if [ "$sftp_count" -eq "$local_count" ]; then
    echo "Todos los archivos locales se encuentran en el servidor remoto $sftp_count/$local_count (sftp/local)."
else
    echo "Archivos en local no encontrados en servidor remoto:"
    
    log_dir="/tmp/disc_serv/daily_recordings_backup/$campaign"
    log_file="$log_dir/${year}-${month}-${day}_missing-files.log"
    mkdir -p "$log_dir" 
    
    for local_file in "${local_array[@]}"; do
        if [[ ! " ${sftp_array[*]} " =~ " $local_file " ]]; then
            echo "$DIRECTORY/$local_file" > "$log_file"
            echo "$DIRECTORY/$local_file"
        fi
    done
fi


