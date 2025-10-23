#!/bin/bash

##
## Script de Backup para Kong API Gateway
## Crea un backup completo de la base de datos PostgreSQL
##

set -e

# Colores
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Configuración
BACKUP_DIR="${BACKUP_DIR:-./backups}"
CONTAINER_NAME="${CONTAINER_NAME:-kong-database}"
DB_USER="${DB_USER:-kong}"
DB_NAME="${DB_NAME:-kong}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/kong-backup-${TIMESTAMP}.sql"
RETENTION_DAYS="${RETENTION_DAYS:-30}"

# Crear directorio de backups si no existe
mkdir -p "${BACKUP_DIR}"

echo -e "${GREEN}=== Kong Database Backup ===${NC}"
echo ""
echo "Timestamp: ${TIMESTAMP}"
echo "Container: ${CONTAINER_NAME}"
echo "Database:  ${DB_NAME}"
echo "Destino:   ${BACKUP_FILE}"
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

# Crear backup
echo -e "${YELLOW}Creando backup...${NC}"
if docker exec "${CONTAINER_NAME}" pg_dump -U "${DB_USER}" "${DB_NAME}" > "${BACKUP_FILE}"; then
    # Comprimir backup
    echo -e "${YELLOW}Comprimiendo backup...${NC}"
    gzip "${BACKUP_FILE}"
    BACKUP_FILE="${BACKUP_FILE}.gz"

    # Obtener tamaño del archivo
    FILE_SIZE=$(du -h "${BACKUP_FILE}" | cut -f1)

    echo -e "${GREEN}✓ Backup creado exitosamente${NC}"
    echo ""
    echo "Archivo: ${BACKUP_FILE}"
    echo "Tamaño:  ${FILE_SIZE}"
else
    echo -e "${RED}Error al crear el backup${NC}"
    exit 1
fi

# Limpiar backups antiguos
echo ""
echo -e "${YELLOW}Limpiando backups antiguos (>${RETENTION_DAYS} días)...${NC}"
DELETED_COUNT=$(find "${BACKUP_DIR}" -name "kong-backup-*.sql.gz" -type f -mtime +${RETENTION_DAYS} -delete -print | wc -l)
if [ "${DELETED_COUNT}" -gt 0 ]; then
    echo -e "${GREEN}✓ ${DELETED_COUNT} backup(s) antiguo(s) eliminado(s)${NC}"
else
    echo -e "${GREEN}✓ No hay backups antiguos para eliminar${NC}"
fi

# Listar backups disponibles
echo ""
echo -e "${GREEN}Backups disponibles:${NC}"
ls -lh "${BACKUP_DIR}"/kong-backup-*.sql.gz 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'

echo ""
echo -e "${GREEN}=== Backup completado ===${NC}"
