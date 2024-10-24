#!/bin/bash

# Función para mostrar información de uso
function uso() {
    echo -e "Uso: $0 <YYYY-MM-DD> --table <table_name>\n"
    echo "Descripción:"
    echo "  Este script ejecuta una consulta MySQL en una base de datos para una fecha específica y tabla seleccionada."
    echo -e "\nArgumentos:"
    echo "  <YYYY-MM-DD>      Fecha en formato 'Año-Mes-Día' (Ejemplo: 2024-10-24)."
    echo "  --table           Nombre de la tabla a consultar. Las opciones válidas son:"
    echo "                    - vicidial_log: Registros de llamadas con detalles como ID de lead, duración, y usuario."
    echo "                    - vicidial_list: Información de leads, incluyendo número de teléfono, código de lead y usuario."
    echo "                    - vicidial_carrier_log: Logs de llamadas por carrier, con detalles de tiempos y canal."
    echo "                    - recording_log: Información de grabaciones, incluyendo duración e identificador de archivo."
    exit 1
}

# Función para ejecutar una consulta MySQL
function ejecutar_consulta() {
    local consulta=$1
    mysql -u "$INTERN_DB_USER" -p"$INTERN_DB_PASS" -D "$INTERN_DB_NAME" --batch -s -NBe "$consulta" | sed "s/\t/','/g; s/^/'/; s/$/'/"
}

# Asegurarse de que el script se llame con al menos un argumento
if [ $# -lt 3 ]; then
    uso
fi

# Cargar configuración
source /opt/disc_serv/daily_db_sync/config.sh
source "$INTERNAL_ENV_FILE"

# Inicializar variables
DATE_ARG=""
TABLE_NAME=""

# Analizar los argumentos de la línea de comandos
while [[ $# -gt 0 ]]; do
    case "$1" in
        --table)
            TABLE_NAME="$2"
            shift 2
            ;;
        *)
            DATE_ARG="$1"
            shift
            ;;
    esac
done

# Validar el formato de la fecha
if ! [[ $DATE_ARG =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
    echo "Error: La fecha debe estar en formato YYYY-MM-DD."
    exit 1
fi

# Definir consultas
declare -A QUERIES
QUERIES=(
    ["vicidial_log"]="SELECT uniqueid, lead_id, list_id, campaign_id, call_date, start_epoch, end_epoch, length_in_sec, status, phone_code, phone_number, user FROM vicidial_log WHERE DATE(call_date) = '$DATE_ARG';"
    ["vicidial_list"]="SELECT lead_id, entry_date, status, user, vendor_lead_code, phone_code, phone_number, security_phrase FROM vicidial_list WHERE DATE(entry_date) = '$DATE_ARG';"
    ["vicidial_carrier_log"]="SELECT uniqueid, call_date, lead_id, channel, dial_time, answered_time FROM vicidial_carrier_log WHERE DATE(call_date) = '$DATE_ARG';"
    ["recording_log"]="SELECT lead_id, length_in_sec, filename FROM recording_log WHERE DATE(start_time) = '$DATE_ARG';"
)

# Validar el nombre de la tabla
if [[ -z "${QUERIES[$TABLE_NAME]}" ]]; then
    echo "Error: Nombre de tabla no válido. Las opciones válidas son: ${!QUERIES[@]}"
    exit 1
fi

# Ejecutar la consulta apropiada basada en el nombre de la tabla
ejecutar_consulta "${QUERIES[$TABLE_NAME]}"
