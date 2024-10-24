#!/bin/bash

# Mostrar uso del script
usage() {
    echo "Uso: $0 -c <codigo> -d <fecha>"
    echo "  -c <codigo>   Código de la campaña"
    echo "  -d <fecha>    Fecha en formato YYYY-MM-DD"
    exit 1
}

# Verificar si se proporcionaron argumentos
if [ $# -eq 0 ]; then
    usage
fi

# Parsear argumentos
while getopts "c:d:" opt; do
    case $opt in
        c) codigo=$OPTARG ;;
        d) date=$OPTARG ;;
        *) usage ;;
    esac
done

# Verificar si se proporcionaron ambos argumentos
if [ -z "$codigo" ] || [ -z "$date" ]; then
    usage
fi

# Convertir la fecha de YYYY-MM-DD a YYYYMMDD
formatted_date=$(echo $date | sed 's/-//g')

# Definir el directorio base
DIRECTORY="/var/spool/asterisk/monitorDONE/MP3"

# Buscar archivos que coincidan con la campaña y la fecha
sudo find $DIRECTORY -type f -name "*${formatted_date}*${codigo}*"