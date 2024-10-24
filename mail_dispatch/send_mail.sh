#!/bin/bash

usage() {
  echo "Uso: $0 \\
  --from FROM \\
  --to TO \\
  --subject SUBJECT \\
  --body BODY

Ejemplo:
  $0 --from 'Servidor de alertas' --to 'usuario@ejemplo.com' --subject 'Alerta de Sistema' --body 'Se ha detectado un problema en el sistema.'"
  exit 1
}

# Analiza las opciones usando getopt
PARSED_OPTIONS=$(getopt -o '' --long from:,to:,subject:,body: -- "$@")
if [ $? -ne 0 ]; then
  usage
fi

eval set -- "$PARSED_OPTIONS"

# Procesa las opciones
while true; do
  case "$1" in
    --from)
      FROM="$2"
      shift 2
      ;;
    --to)
      TO="$2"
      shift 2
      ;;
    --subject)
      SUBJECT="$2"
      shift 2
      ;;
    --body)
      BODY="$2"
      shift 2
      ;;
    --)
      shift
      break
      ;;
    *)
      usage
      ;;
  esac
done

# Verifica que todos los argumentos requeridos están presentes
if [ -z "$BODY" ] || [ -z "$FROM" ] || [ -z "$TO" ] || [ -z "$SUBJECT" ]; then
  usage
fi

DATE=$(date +"%Y-%m-%d %H:%M:%S")
DATE_CH=$(TZ='America/Santiago' date '+%Y-%m-%d %H:%M:%S')
IP=$(curl -s ifconfig.me)

MESSAGE=$(cat <<EOF
To: $TO
Subject: $SUBJECT
Content-Type: text/html; charset=UTF-8

<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <title>$SUBJECT</title>
</head>
<body>
    <p>Estimado soporte,</p>
    <p>$BODY</p>
    <p><b>Información del servidor:</b></p>
    <ul>
      <li><b>IP del servidor:</b> $IP</li>
      <li><b>Fecha y Hora en servidor:</b> $DATE</li>
      <li><b>Hora local de Chile:</b> $DATE_CH</li>
    </ul>
    --
    <br>
    <i>Nota: Este es un mensaje generado automáticamente. Por favor, no responda a este correo.</i>
</body>
</html>
EOF
)

echo "$MESSAGE" | ssmtp -F"$FROM" -t
