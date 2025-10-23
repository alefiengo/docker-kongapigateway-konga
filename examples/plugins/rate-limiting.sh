#!/bin/bash

##
## Ejemplo: Configurar Rate Limiting en Kong
##

set -e

KONG_ADMIN_URL="${KONG_ADMIN_URL:-http://localhost:8001}"
SERVICE_NAME="${1:-example-service}"

echo "Configurando Rate Limiting para el servicio: $SERVICE_NAME"

# Aplicar plugin de rate limiting
PLUGIN_RESPONSE=$(curl -s -X POST "${KONG_ADMIN_URL}/services/${SERVICE_NAME}/plugins" \
  --data "name=rate-limiting" \
  --data "config.minute=100" \
  --data "config.hour=10000" \
  --data "config.policy=local")

PLUGIN_ID=$(echo "$PLUGIN_RESPONSE" | jq -r '.id')

echo "✓ Plugin Rate Limiting configurado: $PLUGIN_ID"
echo ""
echo "Configuración:"
echo "  - 100 requests por minuto"
echo "  - 10,000 requests por hora"
echo ""
echo "Headers de rate limit en las respuestas:"
echo "  - X-RateLimit-Limit-Minute"
echo "  - X-RateLimit-Remaining-Minute"
