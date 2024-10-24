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
    local campaign_info="$3"
    local list_info="$4"

    DATE=$(date +"%Y-%m-%d %H:%M:%S")
    subject="Alerta Discador - Leads detenidos (Lista $list_id) | $DATE"
    body="""
    Se ha detectado que hay llamadas detenidas en la lista con ID $list_id. 
    Es posible que todas las llamadas de la lista $list_id se encuentren afectadas.
    <p><b>Información de campaña:</b></p>
    $(cat $campaign_info)
    <p><b>Información de lista:</b></p>
    $(cat $list_info)
    """

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

    GLOBAL_ERRORS="$LOG_DIR/errors_log"
    
    if [ ! -f "$file_path" ]; then
        echo "$new_content" > "$file_path"
        return
    else
        local old_content=$(cat "$file_path")

        if [ ${#old_content} -gt 1 ] || [ ${#new_content} -gt 1 ]; then
            if [ "$old_content" = "$new_content" ]; then
                current_time=$(date "+%Y-%m-%d %H:%M:%S")
                echo "$current_time ------> ERROR DETECTADO en Lista $list_id" >> "$GLOBAL_ERRORS"
                echo "ALERTA Leads no han cambiado en 15 min..!!" >> "$GLOBAL_ERRORS"

                if [ -f "$campaign_dir/last_error" ]; then
                    echo "El archivo de errores last_error existe." >> "$GLOBAL_ERRORS"
                    if compare_hours "$campaign_dir/last_error"; then
                        echo "Han pasado más de 3 horas desde el último error en last_error, notificar." >> "$GLOBAL_ERRORS"
                        error_date=$(date "+%Y-%m-%d %H:%M:%S")
                        echo "$error_date" > "$campaign_dir/last_error"
                        send_notification "$list_id" "$error_date" "$campaign_dir/campaign_info" "$campaign_dir/list_info"
                    else
                        echo "Han pasado menos de 3 horas del último error en last_error NO notificar." >> "$GLOBAL_ERRORS"
                    fi
                else
                    echo "El archivo de errores last_error no existe. Crea Y notifica." >> "$GLOBAL_ERRORS"
                    error_date=$(date "+%Y-%m-%d %H:%M:%S")
                    echo $error_date > "$campaign_dir/last_error"
                    send_notification "$list_id" "$error_date" "$campaign_dir/campaign_info" "$campaign_dir/list_info"
                fi

                echo "" >> "$GLOBAL_ERRORS"
            else
                # echo "Cambios detectados, actualizando..."
                echo "$new_content" > "$file_path"
            fi
        
        else
            # echo "Ambos archivos están vacíos."
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
        echo "La hora actual SI está adelantada por más de 3 horas respecto a la hora del archivo last_error." >> "$GLOBAL_ERRORS"
        return 0
    else
        echo "La hora actual NO está adelantada por más de 3 horas respecto a la hora del archivo last_error." >> "$GLOBAL_ERRORS"
        return 1
    fi
}

process_campaign() {
    local campaign_id=$1

    # se crea directorio y se almacena info de campaña
    IFS=$'\t' read -r campaign_id campaign_name active campaign_description <<< "$campaign_id"
    local campaign_dir="$LOG_DIR/$campaign_id"
    mkdir -p "$campaign_dir"
    echo -e "<ul>\n<li><b>Campaign ID:</b> $campaign_id </li>\n<li><b>Campaign Name:</b> $campaign_name </li>\n<li><b>Campaign Active:</b> $active </li>\n<li><b>Campaign Description:</b> $campaign_description </li>\n</ul>" > "$campaign_dir/campaign_info"

    # Se almacena info de lista
    output=$(execute_mysql_query "$(get_lists_query $campaign_id)")
    IFS=$'\t' read -r list_id nombre activo descripcion <<< "$output"
    echo -e "<ul>\n<li><b>List ID:</b> $list_id </li>\n<li><b>List Name:</b> $nombre </li>\n<li><b>List Active:</b> $activo </li>\n<li><b>List Description:</b> $descripcion </li>\n</ul>" > "$campaign_dir/list_info"

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