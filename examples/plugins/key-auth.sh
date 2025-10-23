#!/bin/bash

##
## Ejemplo: Configurar Key Authentication en Kong
##

set -e

KONG_ADMIN_URL="${KONG_ADMIN_URL:-http://localhost:8001}"
SERVICE_NAME="${1:-example-service}"
CONSUMER_NAME="${2:-example-consumer}"

echo "Configurando Key Authentication para el servicio: $SERVICE_NAME"

# 1. Aplicar plugin de key-auth
PLUGIN_RESPONSE=$(curl -s -X POST "${KONG_ADMIN_URL}/services/${SERVICE_NAME}/plugins" \
  --data "name=key-auth")

PLUGIN_ID=$(echo "$PLUGIN_RESPONSE" | jq -r '.id')
echo "✓ Plugin Key Auth configurado: $PLUGIN_ID"

# 2. Crear consumer
CONSUMER_RESPONSE=$(curl -s -X POST "${KONG_ADMIN_URL}/consumers" \
  --data "username=${CONSUMER_NAME}")

CONSUMER_ID=$(echo "$CONSUMER_RESPONSE" | jq -r '.id')
echo "✓ Consumer creado: $CONSUMER_ID"

# 3. Crear API key para el consumer
KEY_RESPONSE=$(curl -s -X POST "${KONG_ADMIN_URL}/consumers/${CONSUMER_NAME}/key-auth")

API_KEY=$(echo "$KEY_RESPONSE" | jq -r '.key')
echo "✓ API Key generada: $API_KEY"

echo ""
echo "Configuración completada!"
echo ""
echo "Para usar la API:"
echo "  curl -H 'apikey: ${API_KEY}' http://localhost:8000/example/get"
echo ""
echo "Sin API key obtendrás un 401 Unauthorized"
