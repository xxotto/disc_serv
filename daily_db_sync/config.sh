#!/bon/bash

# Definir las rutas utilizadas en el script
SELECT_DAILY_INFO="/opt/disc_serv/daily_db_sync/select_daily_info.sh"
SEND_TO_DB="/opt/disc_serv/daily_db_sync/send_to_db.sh"
MAIL_SCRIPT="/opt/disc_serv/mail_dispatch/send_mail.sh"
LOG_DIR="/tmp/disc_serv/daily_db_sync"
GENERAL_LOG="$LOG_DIR/general"

# Rutas a los archivos .env
INTERNAL_ENV_FILE="/opt/disc_serv/env/db_internal_env.sh"
EXTERNAL_ENV_FILE="/opt/disc_serv/env/db_external_env.sh"
MAIL_ENV_FILE="/opt/disc_serv/env/mail_db_env.sh"
