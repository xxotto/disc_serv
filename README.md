# Servicios de Discador (`disc_serv`)

Repositorio con servicios de utilidad para la gestión de un Discador.

**Importante:** Es necesario crear el directorio `env` con los siguientes archivos y variables de entorno:

```bash
env/
├── db_internal_env.sh
└── mail_alert_env.sh
```

## Configuración de Variables de Entorno

`db_internal_env.sh`
```bash
INTERN_DB_USER="mysql_user"      # Usuario de la base de datos interna
INTERN_DB_PASS="mysql_password"  # Contraseña de la base de datos interna
INTERN_DB_NAME="mysql_db"        # Nombre de la base de datos interna
```

`mail_alert_env.sh`
```bash
MAIL_FROM="Nombre Apellido"      # Nombre del remitente de los correos de alerta
MAIL_TO="user@domain.com"        # Dirección de correo del destinatario
```

## Servicios Disponibles

### 1. `mail_dispatch`

Servicio encargado de despachar correos electrónicos. Requiere tener ssmtp instalado para el envío de correos.

Uso del Script `send_mail.sh`:

```bash
./send_mail.sh --from 'Servidor de alertas' \
               --to 'user@domain.com' \
               --subject 'Error en el Sistema' \
               --body 'Se ha detectado un problema en el sistema.'
```

### 2. `alert_system`

Sistema de alerta diseñado para detectar leads detenidos. Se recomienda agregar un cron job que ejecute el script cada 15 minutos para comparar el estado actual de los leads con el de hace 15 minutos y detectar si hay leads que se hayan detenido.

Ejemplo de Cron Job:

```bash
# Verifica si hay leads detenidos cada 15 minutos, desde las 08:00 hasta las 21:00
*/15 8-21 * * * /opt/disc_serv/alert_system/main.sh
```
