#!/bin/bash

##
## Script de Restauración para Kong API Gateway
## Restaura un backup de la base de datos PostgreSQL
##

set -e

# Colores
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuración
CONTAINER_NAME="${CONTAINER_NAME:-kong-database}"
DB_USER="${DB_USER:-kong}"
DB_NAME="${DB_NAME:-kong}"
BACKUP_FILE="$1"

# Función de ayuda
show_help() {
    echo "Uso: $0 <archivo-backup>"
    echo ""
    echo "Ejemplos:"
    echo "  $0 backups/kong-backup-20240307-123456.sql"
    echo "  $0 backups/kong-backup-20240307-123456.sql.gz"
    echo ""
    echo "Variables de entorno opcionales:"
    echo "  CONTAINER_NAME  - Nombre del contenedor (default: kong-database)"
    echo "  DB_USER        - Usuario de PostgreSQL (default: kong)"
    echo "  DB_NAME        - Nombre de la base de datos (default: kong)"
}

# Validar argumentos
if [ -z "${BACKUP_FILE}" ]; then
    echo -e "${RED}Error: Debes especificar un archivo de backup${NC}"
    echo ""
    show_help
    exit 1
fi

if [ ! -f "${BACKUP_FILE}" ]; then
    echo -e "${RED}Error: El archivo ${BACKUP_FILE} no existe${NC}"
    exit 1
fi

echo -e "${GREEN}=== Kong Database Restore ===${NC}"
echo ""
echo "Container: ${CONTAINER_NAME}"
echo "Database:  ${DB_NAME}"
echo "Archivo:   ${BACKUP_FILE}"
echo ""

# Verificar que el contenedor esté corriendo
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "${RED}Error: El contenedor ${CONTAINER_NAME} no está corriendo${NC}"
    exit 1
fi

# Verificar que PostgreSQL esté saludable
echo -e "${YELLOW}Verificando salud de PostgreSQL...${NC}"
if ! docker exec "${CONTAINER_NAME}" pg_isready -U "${DB_USER}" > /dev/null 2>&1; then
    echo -e "${RED}Error: PostgreSQL no está respondiendo${NC}"
    exit 1
fi
echo -e "${GREEN}✓ PostgreSQL saludable${NC}"
echo ""

# Advertencia
echo -e "${RED}⚠ ADVERTENCIA ⚠${NC}"
echo -e "${YELLOW}Esta operación sobrescribirá la base de datos actual.${NC}"
echo -e "${YELLOW}Se recomienda crear un backup antes de continuar.${NC}"
echo ""
read -p "¿Deseas continuar? [y/N] " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Restauración cancelada${NC}"
    exit 0
fi

# Determinar si el archivo está comprimido
IS_GZIPPED=false
if [[ "${BACKUP_FILE}" == *.gz ]]; then
    IS_GZIPPED=true
    echo -e "${YELLOW}Archivo comprimido detectado${NC}"
fi

# Restaurar
echo ""
echo -e "${YELLOW}Restaurando backup...${NC}"

if [ "${IS_GZIPPED}" = true ]; then
    # Descomprimir y restaurar
    if gunzip -c "${BACKUP_FILE}" | docker exec -i "${CONTAINER_NAME}" psql -U "${DB_USER}" -d "${DB_NAME}" > /dev/null; then
        echo -e "${GREEN}✓ Backup restaurado exitosamente${NC}"
    else
        echo -e "${RED}Error al restaurar el backup${NC}"
        exit 1
    fi
else
    # Restaurar directamente
    if docker exec -i "${CONTAINER_NAME}" psql -U "${DB_USER}" -d "${DB_NAME}" < "${BACKUP_FILE}" > /dev/null; then
        echo -e "${GREEN}✓ Backup restaurado exitosamente${NC}"
    else
        echo -e "${RED}Error al restaurar el backup${NC}"
        exit 1
    fi
fi

# Verificar la restauración
echo ""
echo -e "${YELLOW}Verificando restauración...${NC}"
TABLE_COUNT=$(docker exec "${CONTAINER_NAME}" psql -U "${DB_USER}" -d "${DB_NAME}" -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" | tr -d ' ')
echo -e "${GREEN}✓ Tablas en la base de datos: ${TABLE_COUNT}${NC}"

echo ""
echo -e "${GREEN}=== Restauración completada ===${NC}"
echo -e "${YELLOW}Reinicia Kong para aplicar los cambios: docker-compose restart kong${NC}"
