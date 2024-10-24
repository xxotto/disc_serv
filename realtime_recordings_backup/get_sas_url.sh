#!/bin/bash

source /opt/disc_serv/realtime_recordings_backup/config.sh

# Función para mostrar el uso del script
mostrar_uso() {
    echo "Uso: $0 --filepath FILEPATH"
    echo "Ejemplo: $0 --filepath path/to/audio.mp3"
}

# Inicializar variables
FILEPATH=""

# Procesar argumentos de línea de comandos
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --filepath) FILEPATH="$2"; shift ;;
        *) echo "Argumento desconocido: $1"; mostrar_uso; exit 1 ;;
    esac
    shift
done

# Mostrar uso si no se proporcionan argumentos
if [[ -z "$FILEPATH" ]]; then
    mostrar_uso
    exit 1
fi

# Extraer campaña, año, mes, día y archivo del filepath
CAMPAIGN_ID=$(echo "$FILEPATH" | cut -d'/' -f1)
YEAR=$(echo "$FILEPATH" | cut -d'/' -f2)
MONTH=$(echo "$FILEPATH" | cut -d'/' -f3)
DAY=$(echo "$FILEPATH" | cut -d'/' -f4)
FILE=$(echo "$FILEPATH" | cut -d'/' -f5)

# Construir el payload
PAYLOAD=$(cat <<EOF
{
    "campaign_id": "$CAMPAIGN_ID",
    "year": "$YEAR",
    "month": "$MONTH",
    "day": "$DAY",
    "file": "$FILE"
}
EOF
)

# Realizar la solicitud curl
RESPONSE=$(curl -s -X POST "$URL" \
     -H "Content-Type: application/json" \
     -H "user_id: $USER_ID" \
     -H "password: $PASSWORD" \
     -d "$PAYLOAD")

# Extraer el valor de la URL de la respuesta
URL_VALUE=$(echo "$RESPONSE" | grep -oP '(?<="url":")[^"]*')

# Imprimir el resultado
if [ -n "$URL_VALUE" ]; then
    echo "$URL_VALUE"
else
    echo "$(date) | NO se generó la url $RESPONSE"
fi