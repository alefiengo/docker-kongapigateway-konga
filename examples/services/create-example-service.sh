#!/bin/bash

##
## Ejemplo: Crear un servicio básico en Kong
##

set -e

KONG_ADMIN_URL="${KONG_ADMIN_URL:-http://localhost:8001}"

echo "Creando servicio de ejemplo en Kong..."

# Crear servicio
SERVICE_RESPONSE=$(curl -s -X POST "${KONG_ADMIN_URL}/services" \
  --data "name=example-service" \
  --data "url=https://httpbin.org")

SERVICE_ID=$(echo "$SERVICE_RESPONSE" | jq -r '.id')

echo "✓ Servicio creado: $SERVICE_ID"

# Crear ruta para el servicio
ROUTE_RESPONSE=$(curl -s -X POST "${KONG_ADMIN_URL}/services/example-service/routes" \
  --data "name=example-route" \
  --data "paths[]=/example")

ROUTE_ID=$(echo "$ROUTE_RESPONSE" | jq -r '.id')

echo "✓ Ruta creada: $ROUTE_ID"

echo ""
echo "Servicio configurado correctamente!"
echo "Prueba con: curl http://localhost:8000/example/get"
