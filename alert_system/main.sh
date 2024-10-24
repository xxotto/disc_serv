#!/bin/bash

# Cargar configuraciones de rutas
source /opt/disc_serv/alert_system/config.sh

# Cargar las variables de entorno de MySQL Interno, Externo y Correo
for ENV_FILE in "$INTERNAL_ENV_FILE" "$MAIL_ENV_FILE"; do
    if [ -f "$ENV_FILE" ]; then
        export $(grep -v '^#' "$ENV_FILE" | xargs)
    else
        echo "Archivo $ENV_FILE no encontrado. Por favor, asegúrate de que exista."
        exit 1
    fi
done

source "$MAIL_ENV_FILE"
source "$INTERNAL_ENV_FILE"
source "$QUERIES"

# Función para ejecutar consultas MySQL
execute_mysql_query() {
    local query="$1"
    mysql   -u "$INTERN_DB_USER" \
            -p"$INTERN_DB_PASS" \
            -D "$INTERN_DB_NAME" \
            -NBe "$query"
}

# Función para enviar notificaciones
send_notification() {
    local list_id="$1"
    local aprox_hour="$2"

    DATE=$(date +"%Y-%m-%d %H:%M:%S")
    subject="Alerta Discador - Leads detenidos (Lista $list_id) | $DATE"
    body="Se ha detectado que hay llamadas detenidas en la lista con ID $list_id. Es posible que todas las llamadas de la lista $list_id se encuentren afectadas."

    "$MAIL_SCRIPT" \
      --from "$MAIL_FROM" \
      --to "$MAIL_TO" \
      --subject "$subject" \
      --body "$body"
}

compare_and_update_file() {
    local file_path=$1
    local new_content=$2
    local campaign_dir=$3
    local list_id=$4

    if [ ! -f "$file_path" ]; then
        echo "$new_content" > "$file_path"
        return
    else
        local old_content=$(cat "$file_path")

        if [ ${#old_content} -gt 1 ] || [ ${#new_content} -gt 1 ]; then
            if [ "$old_content" = "$new_content" ]; then
                echo "ALARMA NO HAN CAMBIADO EN 15 min..!!"

                if [ -f "$campaign_dir/last_error" ]; then
                    echo "El archivo existe."
                    if compare_hours "$campaign_dir/last_error"; then
                        echo "Han pasado 3 horas desde el error, notificar"
                        error_date=$(date "+%Y-%m-%d %H:%M:%S")
                        echo "$error_date" > "$campaign_dir/last_error"
                        send_notification "$list_id" "$error_date"
                    else
                        echo "Han pasado menos de 3 horas del error no notificar."
                        :
                    fi
                else
                    echo "El archivo no existe. Crea Y notifica"
                    error_date=$(date "+%Y-%m-%d %H:%M:%S")
                    echo $error_date > "$campaign_dir/last_error"
                    send_notification "$list_id" "$error_date"
                fi

            else
                echo "Cambios detectados, actualizando..."
                echo "$new_content" > "$file_path"
            fi
        else
            echo "Ambos están vacíos"
            :
        fi

    fi
}


compare_hours() {
    local file_path=$1

    file_time=$(cat "$file_path")
    file_time_sec=$(date -d "$file_time" +%s)
    current_time=$(date "+%Y-%m-%d %H:%M:%S")
    current_time_sec=$(date +%s)
    diff_sec=$((current_time_sec - file_time_sec))

    if [ $diff_sec -gt 10800 ]; then
        echo "La hora actual está adelantada por más de 3 horas respecto a la hora del archivo."
        return 0
    else
        echo "La hora actual no está adelantada por más de 3 horas respecto a la hora del archivo."
        return 1
    fi
}

process_campaign() {
    local campaign_id=$1

    # se crea directorio y se almacena info de campaña
    IFS=$'\t' read -r campaign_id campaign_name active campaign_description <<< "$campaign_id"
    local campaign_dir="$LOG_DIR/$campaign_id"
    mkdir -p "$campaign_dir"
    echo -e "Campaign ID: $campaign_id\nCampaign Name: $campaign_name\nCampaign Active: $active\nCampaign Description: $campaign_description" > "$campaign_dir/campaign_info"

    # Se almacena info de lista
    output=$(execute_mysql_query "$(get_lists_query $campaign_id)")
    IFS=$'\t' read -r list_id nombre activo descripcion <<< "$output"
    echo "---------- $list_id ----------"
    echo -e "List ID: $list_id\nList Name: $nombre\nList Active: $activo\nList Description: $descripcion" > "$campaign_dir/list_info"

    # se compara leads en lista del query con los almacenados
    leads_in_list=$(execute_mysql_query "$(get_leads_in_list_query $list_id)")
    compare_and_update_file "$campaign_dir/list_leads" "$leads_in_list" "$campaign_dir" "$list_id"

    # Se compara leads en hopper del query con los almacenados
    leads_in_hopper=$(execute_mysql_query "$(get_leads_in_hopper_query $campaign_id)")
    compare_and_update_file "$campaign_dir/hopper_leads" "$leads_in_hopper" "$campaign_dir" "$list_id"

    echo "$(date "+%Y-%m-%d %H:%M:%S")" > "$campaign_dir/last_check"
}

main() {
    mkdir -p "$LOG_DIR"
    mapfile -t CAMPAIGNS < <(execute_mysql_query "$CAMPAIGN_QUERY")

    for campaign_id in "${CAMPAIGNS[@]}"; do
        process_campaign "$campaign_id"
    done
}

main