#!/bin/bash

##
## Ejemplo: Configurar CORS en Kong
##

set -e

KONG_ADMIN_URL="${KONG_ADMIN_URL:-http://localhost:8001}"
SERVICE_NAME="${1:-example-service}"
ALLOWED_ORIGIN="${2:-*}"

echo "Configurando CORS para el servicio: $SERVICE_NAME"

# Aplicar plugin de CORS
PLUGIN_RESPONSE=$(curl -s -X POST "${KONG_ADMIN_URL}/services/${SERVICE_NAME}/plugins" \
  --data "name=cors" \
  --data "config.origins=${ALLOWED_ORIGIN}" \
  --data "config.methods=GET,POST,PUT,DELETE,OPTIONS" \
  --data "config.headers=Accept,Authorization,Content-Type,X-Custom-Header" \
  --data "config.exposed_headers=X-Auth-Token" \
  --data "config.credentials=true" \
  --data "config.max_age=3600")

PLUGIN_ID=$(echo "$PLUGIN_RESPONSE" | jq -r '.id')

echo "✓ Plugin CORS configurado: $PLUGIN_ID"
echo ""
echo "Configuración:"
echo "  - Orígenes permitidos: ${ALLOWED_ORIGIN}"
echo "  - Métodos: GET, POST, PUT, DELETE, OPTIONS"
echo "  - Credentials: true"
echo "  - Max Age: 3600 segundos"
echo ""
echo "Para producción, especifica orígenes exactos:"
echo "  bash $0 ${SERVICE_NAME} https://example.com"
