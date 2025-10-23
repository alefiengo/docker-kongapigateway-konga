# Ejemplos de Configuración de Kong

Esta carpeta contiene ejemplos de configuración comunes para Kong API Gateway.

## Estructura

```
examples/
├── plugins/        # Configuraciones de plugins
├── services/       # Definiciones de servicios
├── routes/         # Configuraciones de rutas
└── README.md       # Este archivo
```

## Uso

### Opción 1: Via Admin API (curl)

```bash
# Ejecutar directamente los scripts de ejemplo
bash examples/services/create-example-service.sh
```

### Opción 2: Via Konga UI

1. Acceder a Konga (http://localhost:1337)
2. Usar los ejemplos como referencia para configurar via interfaz web

### Opción 3: Via decK (declarativo)

```bash
# Instalar decK
curl -sL https://github.com/kong/deck/releases/download/v1.28.0/deck_1.28.0_linux_amd64.tar.gz -o deck.tar.gz
tar -xf deck.tar.gz -C /tmp
sudo cp /tmp/deck /usr/local/bin/

# Aplicar configuración
deck sync -s examples/deck-config.yaml
```

## Ejemplos Disponibles

### Services

- **Example HTTP Service**: Servicio backend HTTP básico
- **Example HTTPS Service**: Servicio backend HTTPS
- **Microservice Example**: Configuración de múltiples microservicios

### Routes

- **Path-based Routing**: Ruteo basado en paths
- **Host-based Routing**: Ruteo basado en hosts
- **Method-based Routing**: Ruteo basado en métodos HTTP

### Plugins

- **Authentication**:
  - Key Authentication
  - JWT
  - OAuth 2.0
  - Basic Auth

- **Security**:
  - Rate Limiting
  - IP Restriction
  - CORS
  - Request Size Limiting

- **Traffic Control**:
  - Request Transformer
  - Response Transformer
  - Proxy Cache

- **Logging & Monitoring**:
  - File Log
  - HTTP Log
  - Prometheus

## Tips

1. Siempre probar configuraciones en un entorno de desarrollo primero
2. Revisar los logs después de aplicar cambios: `docker-compose logs -f kong`
3. Usar el Admin API para verificar configuración: `curl http://localhost:8001/services`
4. Consultar la documentación oficial de plugins: https://docs.konghq.com/hub/

## Contribuir

Si tienes ejemplos útiles de configuración, considera contribuir al proyecto.
