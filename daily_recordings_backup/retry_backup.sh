#!/bin/bash

# Función para mostrar uso del script
usage() {
    echo "Uso: $0 -c <campaña> -d <fecha> -b <tamaño del lote>"
    echo "  -c <campaña>     ID de campaña a utilizar (ejm. Anx5010)"
    echo "  -d <fecha>       Fecha en formato YYYY-MM-DD"
    echo "  -b <tamaño del lote> Tamaño del lote para la subida de archivos"
    exit 1
}

# Leer los argumentos del script
while getopts ":c:d:b:" opt; do
    case ${opt} in
        c ) campaign=$OPTARG ;;
        d ) date=$OPTARG ;;
        b ) batch_size=$OPTARG ;;
        \? ) usage ;;
    esac
done
shift $((OPTIND -1))

# Verificar que todos los parámetros requeridos están presentes
if [ -z "${campaign}" ] || [ -z "${date}" ] || [ -z "${batch_size}" ]; then
    usage
fi

helpers_dir="/opt/disc_serv/daily_recordings_backup/helpers"

recordings=$(cat /tmp/disc_serv/daily_recordings_backup/$campaign/${date}_missing-files.log)

if [ -n "$recordings" ]; then
    echo "Grabaciones no enviadas encontradas el $date para la campaña $campaign."
    "$helpers_dir/make_dirs_in_sftp.sh" -c "$campaign" -d "$date"
    "$helpers_dir/upload_files_to_sftp.sh" -c "$campaign" -d "$date" -b "$batch_size" -r "$recordings"
    "$helpers_dir/verify_recording_uploads.sh" -c "$campaign" -d "$date"
else
    echo "No se encontraron grabaciones del $date para la campaña $campaign"
fi
