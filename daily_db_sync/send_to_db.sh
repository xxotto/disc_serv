#!/bin/bash

usage() {
    echo "Usage: $0 <YYYY-MM-DD> --table <table_name>"
    exit 1
}

# Validar argumentos
if [ -z "$1" ] || [ -z "$2" ] || [ "$2" != "--table" ] || [ -z "$3" ]; then
    usage
fi

DATE_ARG="$1"
TABLE_NAME="$3"

# Cargar configuraciones
source /opt/disc_serv/daily_db_sync/config.sh
source "$EXTERNAL_ENV_FILE"
mkdir -p "$LOG_DIR"

# Selccionar registros con select_daily_info.sh <YYYY-MM-DD> --table <table_name>
outputs=$("$SELECT_DAILY_INFO" "$DATE_ARG" --table "$TABLE_NAME")

# Si no hay registros en la fecha que se solicita termina el script
if [ -z "$outputs" ]; then
    # echo "No hay datos para procesar el $1."
    exit 0
fi

# Inicializar variables
BATCH_SIZE=500
BATCH_COUNT=0

# Definir consultas de inserción
declare -A INSERT_QUERIES
INSERT_QUERIES=(
    ["vicidial_log"]="INSERT INTO vicidial_log (uniqueid, lead_id, list_id, campaign_id, call_date, start_epoch, end_epoch, length_in_sec, status, phone_code, phone_number, user) VALUES "
    ["vicidial_list"]="INSERT INTO vicidial_list (lead_id, entry_date, status, user, vendor_lead_code, phone_code, phone_number, security_phrase) VALUES "
    ["vicidial_carrier_log"]="INSERT INTO vicidial_carrier_log (uniqueid, call_date, lead_id, channel, dial_time, answered_time) VALUES "
    ["recording_log"]="INSERT INTO recording_log (lead_id, length_in_sec, filename) VALUES "
)

# Validar el nombre de la tabla
if [[ -z "${INSERT_QUERIES[$TABLE_NAME]}" ]]; then
    echo "Error: Nombre de tabla no válido. Las opciones válidas son: ${!INSERT_QUERIES[@]}"
    exit 1
fi

INSERT_QUERY="${INSERT_QUERIES[$TABLE_NAME]}"

# Ejecuta la query y si hay error genera un log
execute_and_log_query() {
    query_output=$(mysql -h "$EXTERN_DB_HOST" -P "$EXTERN_DB_PORT" -u "$EXTERN_DB_USER" -p"$EXTERN_DB_PASS" -D "$EXTERN_DB_DB" -e "$INSERT_QUERY;" 2>&1)
    if [ -n "$query_output" ]; then
        INSERT_QUERY=$(echo "$INSERT_QUERY" | tr -d '\n')
        log_line="$(date '+%Y-%m-%d %H:%M:%S') | $query_output | $INSERT_QUERY "
        echo "$log_line" >> "$LOG_DIR/$(date '+%Y-%m-%d')"
        echo "$log_line" >> "$GENERAL_LOG"
    fi
}

# Insertar en la DB de respaldo en lotes de 500 (por velocidad)
while IFS= read -r line; do

    # Si no es el primer registro, añadir una coma para separar los valores
    if [ $BATCH_COUNT -gt 0 ]; then
        INSERT_QUERY+=","
    fi

    INSERT_QUERY+="($line)"
    ((BATCH_COUNT++))
    
    if [ $BATCH_COUNT -eq $BATCH_SIZE ]; then
        # Ejecutar la inserción cuando se alcanza el tamaño del lote
        execute_and_log_query

        # Reiniciar la consulta y el contador para el siguiente lote
        INSERT_QUERY="${INSERT_QUERIES[$TABLE_NAME]}"
        BATCH_COUNT=0
    fi
done <<< "$outputs"

# Verificar último lote sobrante con menos de 500 registros
if [ $BATCH_COUNT -gt 0 ]; then
    execute_and_log_query
fi

