#!/bin/bash

# Definir las rutas utilizadas en el script
LOG_DIR="/tmp/disc_serv/alert_system"
MAIL_SCRIPT="/opt/disc_serv/mail_dispatch/send_mail.sh"
QUERIES="/opt/disc_serv/alert_system/queries.sh"

# Rutas a los archivos .env
INTERNAL_ENV_FILE="/opt/disc_serv/env/db_internal_env.sh"
MAIL_ENV_FILE="/opt/disc_serv/env/mail_alert_env.sh"
