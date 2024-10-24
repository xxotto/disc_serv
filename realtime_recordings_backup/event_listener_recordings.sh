#!/bin/bash

source /opt/disc_serv/realtime_recordings_backup/config.sh
source "$CREDENTIALS"

# Función para verificar si el archivo es candidato para backup
is_candidate_for_backup() {
    local file_name="$1"
    local last_section="${file_name##*_}"
    last_section="${last_section%%-*}"

    for campaign in "${RESTRICTED_CAMPAIGNS[@]}"; do
        if [[ "$last_section" == "$campaign" ]]; then
            return 1
        fi
    done
    return 0
}

# Función para subir el archivo a Azure Blob Storage
upload_to_azure_blob() {
    local filepath="$1"
    local filename=$(basename "$filepath")

    local full_campaign_id=$(echo "$filename" | awk -F'_' '{print $4}')
    local campaign_id=$(echo "$full_campaign_id" | awk -F'-' '{print $1}')

    local date_str=$(echo "$filename" | awk -F'_' '{print $2}')
    local year=$(echo "$date_str" | cut -c1-4)
    local month=$(echo "$date_str" | cut -c5-6)
    local day=$(echo "$date_str" | cut -c7-8)

    local destination_path="${campaign_id}/${year}/${month}/${day}/${filename}"
    local sas_url=$("$GET_SAS_URL" --filepath "$destination_path")

    azcopy copy "$filepath" "$sas_url"  > /dev/null 2>&1
}

# Mostrar uso si no se pasan argumentos
if [[ $# -eq 0 ]]; then
    echo "Uso: $0 --run"
    exit 1
fi

# Iniciar el proceso solo si se pasa el argumento --run
if [[ "$1" == "--run" ]]; then
    inotifywait -m -e create --format '%w%f' "$WATCH_DIR" | while read NEW_FILE
    do
        if is_candidate_for_backup "$NEW_FILE"; then
            timestamp=$(date +"%Y-%m-%d %H:%M:%S")
            echo "[$timestamp] Backing up $NEW_FILE"
            upload_to_azure_blob "$NEW_FILE"
        fi
    done
else
    echo "Uso: $0 --run"
    exit 1
fi