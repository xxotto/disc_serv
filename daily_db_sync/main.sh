#!/bin/bash

source /opt/disc_serv/daily_db_sync/config.sh
source "$MAIL_ENV_FILE"

yesterday=$(date -d "yesterday" +%Y-%m-%d)
tables=("vicidial_log" "vicidial_list" "vicidial_carrier_log" "recording_log")

for table in "${tables[@]}"; do
    "$SEND_TO_DB" "$yesterday" --table "$table"
done

# Si hay log de errores entonces envía esos errores vía mail
daily_log="$LOG_DIR/$(date '+%Y-%m-%d')"
if [ -f "$daily_log" ]; then
    DATE=$(date +"%Y-%m-%d %H:%M:%S")
    subject="Alerta Discador - Error en el backup diario de DB ($yesterday) | $DATE"
    body=$"Se identificaron errores al enviar registros del "$DATE_ARG" al respaldo del discador.
    NO todos los registros del "$DATE_ARG" han sido respaldados."
    
    # Envía una alerta de error vía mail
    "$MAIL_SCRIPT" \
      --from "$MAIL_FROM" \
      --to "$MAIL_TO" \
      --subject "$subject" \
      --body "$body"

    echo "" >> "$DAILY_LOG"    
fi