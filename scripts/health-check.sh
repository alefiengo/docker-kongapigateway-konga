#!/bin/bash

##
## Script de Health Check para Kong API Gateway Stack
## Verifica el estado de todos los servicios
##

set -e

# Colores
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuración
KONG_ADMIN_URL="${KONG_ADMIN_URL:-http://localhost:8001}"
KONG_PROXY_URL="${KONG_PROXY_URL:-http://localhost:8000}"
KONGA_URL="${KONGA_URL:-http://localhost:1337}"
DB_CONTAINER="${DB_CONTAINER:-kong-database}"

# Contadores
PASSED=0
FAILED=0

# Función para imprimir resultado
print_result() {
    local service="$1"
    local status="$2"
    local message="$3"

    if [ "${status}" = "ok" ]; then
        echo -e "${GREEN}✓${NC} ${service}: ${GREEN}${message}${NC}"
        ((PASSED++))
    else
        echo -e "${RED}✗${NC} ${service}: ${RED}${message}${NC}"
        ((FAILED++))
    fi
}

# Banner
echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Kong Stack Health Check               ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""

# 1. Docker Compose Services
echo -e "${YELLOW}[1] Verificando servicios Docker...${NC}"
echo ""

SERVICES=("kong-database" "kong-migrations" "kong" "konga")
for service in "${SERVICES[@]}"; do
    if docker ps --format '{{.Names}}' | grep -q "^${service}$"; then
        STATUS=$(docker inspect -f '{{.State.Status}}' "${service}")
        if [ "${STATUS}" = "running" ]; then
            print_result "${service}" "ok" "Running"
        else
            print_result "${service}" "error" "Not running (${STATUS})"
        fi
    else
        print_result "${service}" "error" "Container not found"
    fi
done

echo ""

# 2. PostgreSQL
echo -e "${YELLOW}[2] Verificando PostgreSQL...${NC}"
echo ""

if docker exec "${DB_CONTAINER}" pg_isready -U kong > /dev/null 2>&1; then
    # Obtener versión
    PG_VERSION=$(docker exec "${DB_CONTAINER}" psql -U kong -t -c "SELECT version();" | head -n1 | awk '{print $2}')
    print_result "PostgreSQL" "ok" "Ready (v${PG_VERSION})"

    # Verificar conexiones
    CONNECTIONS=$(docker exec "${DB_CONTAINER}" psql -U kong -t -c "SELECT count(*) FROM pg_stat_activity;" | tr -d ' ')
    echo -e "  ${BLUE}ℹ${NC} Conexiones activas: ${CONNECTIONS}"

    # Verificar tablas de Kong
    TABLES=$(docker exec "${DB_CONTAINER}" psql -U kong -d kong -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" | tr -d ' ')
    echo -e "  ${BLUE}ℹ${NC} Tablas en la base de datos: ${TABLES}"
else
    print_result "PostgreSQL" "error" "Not responding"
fi

echo ""

# 3. Kong Admin API
echo -e "${YELLOW}[3] Verificando Kong Admin API...${NC}"
echo ""

if KONG_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${KONG_ADMIN_URL}"); then
    if [ "${KONG_STATUS}" = "200" ]; then
        # Obtener información de Kong
        KONG_INFO=$(curl -s "${KONG_ADMIN_URL}" | jq -r '.version // "unknown"' 2>/dev/null || echo "unknown")
        print_result "Kong Admin API" "ok" "Responding (Kong ${KONG_INFO})"

        # Verificar servicios configurados
        SERVICES_COUNT=$(curl -s "${KONG_ADMIN_URL}/services" | jq '.data | length' 2>/dev/null || echo "0")
        ROUTES_COUNT=$(curl -s "${KONG_ADMIN_URL}/routes" | jq '.data | length' 2>/dev/null || echo "0")
        echo -e "  ${BLUE}ℹ${NC} Servicios configurados: ${SERVICES_COUNT}"
        echo -e "  ${BLUE}ℹ${NC} Rutas configuradas: ${ROUTES_COUNT}"
    else
        print_result "Kong Admin API" "error" "HTTP ${KONG_STATUS}"
    fi
else
    print_result "Kong Admin API" "error" "No response"
fi

echo ""

# 4. Kong Proxy
echo -e "${YELLOW}[4] Verificando Kong Proxy...${NC}"
echo ""

if PROXY_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${KONG_PROXY_URL}"); then
    if [ "${PROXY_STATUS}" = "404" ] || [ "${PROXY_STATUS}" = "200" ]; then
        print_result "Kong Proxy" "ok" "Responding (HTTP ${PROXY_STATUS})"
    else
        print_result "Kong Proxy" "error" "HTTP ${PROXY_STATUS}"
    fi
else
    print_result "Kong Proxy" "error" "No response"
fi

echo ""

# 5. Kong Status API
echo -e "${YELLOW}[5] Verificando Kong Status API...${NC}"
echo ""

if STATUS_RESPONSE=$(curl -s "${KONG_ADMIN_URL}/status"); then
    DB_REACHABLE=$(echo "${STATUS_RESPONSE}" | jq -r '.database.reachable // false')
    if [ "${DB_REACHABLE}" = "true" ]; then
        print_result "Kong Status" "ok" "Database reachable"

        # Mostrar métricas
        CONNECTIONS_ACTIVE=$(echo "${STATUS_RESPONSE}" | jq -r '.server.connections_active // 0')
        CONNECTIONS_ACCEPTED=$(echo "${STATUS_RESPONSE}" | jq -r '.server.connections_accepted // 0')
        echo -e "  ${BLUE}ℹ${NC} Conexiones activas: ${CONNECTIONS_ACTIVE}"
        echo -e "  ${BLUE}ℹ${NC} Conexiones aceptadas: ${CONNECTIONS_ACCEPTED}"
    else
        print_result "Kong Status" "error" "Database not reachable"
    fi
else
    print_result "Kong Status" "error" "No response"
fi

echo ""

# 6. Konga UI
echo -e "${YELLOW}[6] Verificando Konga UI...${NC}"
echo ""

if KONGA_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${KONGA_URL}"); then
    if [ "${KONGA_STATUS}" = "200" ]; then
        print_result "Konga UI" "ok" "Responding"
    else
        print_result "Konga UI" "error" "HTTP ${KONGA_STATUS}"
    fi
else
    print_result "Konga UI" "error" "No response"
fi

echo ""

# Resumen
echo -e "${BLUE}╔════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Resumen                                ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${GREEN}Passed:${NC} ${PASSED}"
echo -e "  ${RED}Failed:${NC} ${FAILED}"
echo ""

# Exit code
if [ "${FAILED}" -gt 0 ]; then
    echo -e "${RED}❌ Algunas verificaciones fallaron${NC}"
    exit 1
else
    echo -e "${GREEN}✅ Todos los servicios están saludables${NC}"
    exit 0
fi
