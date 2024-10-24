#!/bin/bash
source /opt/disc_serv/env/sftp_env.sh

# Array de campañas
date=$(date --date="yesterday" +%Y-%m-%d)

# Iterar sobre cada campaña y ejecutar el script backup_campaign_recordings.sh
# en caso de que existan grabaciones para la fecha especificada
for campaign in "${campaigns[@]}"; do
    /opt/disc_serv/daily_recordings_backup/backup_campaign_recordings.sh -c "$campaign" -d "$date" -b "$batch_size"
done
