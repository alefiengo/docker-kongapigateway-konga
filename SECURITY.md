# Guía de Seguridad

Esta guía describe las mejores prácticas de seguridad para desplegar y operar Kong API Gateway con Konga en entornos de producción.

## Tabla de Contenidos

- [Configuración Inicial Segura](#configuración-inicial-segura)
- [Gestión de Credenciales](#gestión-de-credenciales)
- [Seguridad de Red](#seguridad-de-red)
- [Configuración de Kong](#configuración-de-kong)
- [Hardening de Contenedores](#hardening-de-contenedores)
- [Monitoreo y Auditoría](#monitoreo-y-auditoría)
- [Actualizaciones y Parches](#actualizaciones-y-parches)
- [Respuesta a Incidentes](#respuesta-a-incidentes)

## Configuración Inicial Segura

### 1. Cambiar Credenciales por Defecto

**CRÍTICO**: Antes de desplegar en producción, cambiar todas las credenciales por defecto.

```bash
# Editar .env y cambiar:
POSTGRES_PASSWORD=tu_password_muy_seguro_aqui
KONG_PG_PASSWORD=tu_password_muy_seguro_aqui
KONGA_TOKEN_SECRET=genera_un_token_aleatorio_largo
```

**Generar passwords seguros:**

```bash
# Para PostgreSQL
openssl rand -base64 32

# Para Konga Token Secret (más largo)
openssl rand -base64 64
```

### 2. Deshabilitar Registro Público de Konga

En producción, solo el administrador debe poder crear cuentas:

```bash
# En .env o docker-compose.prod.yml
KONGA_ALLOW_SIGNUP=false
```

### 3. Usar Variables de Entorno

**NUNCA** hardcodear credenciales en archivos de configuración versionados.

## Gestión de Credenciales

### Secretos de Docker

Para mayor seguridad, usar Docker Secrets en Docker Swarm:

```yaml
# docker-compose.secrets.yml
secrets:
  postgres_password:
    external: true
  kong_password:
    external: true

services:
  kong-database:
    secrets:
      - postgres_password
    environment:
      POSTGRES_PASSWORD_FILE: /run/secrets/postgres_password
```

### Vault o Gestores de Secretos

Para producción empresarial, considerar:

- HashiCorp Vault
- AWS Secrets Manager
- Azure Key Vault
- Google Secret Manager

### Rotación de Credenciales

**Política recomendada:**

- Rotar passwords de base de datos cada 90 días
- Rotar tokens de aplicación cada 30 días
- Usar passwords únicos por entorno (dev/staging/prod)

## Seguridad de Red

### 1. Aislar Servicios

**Configuración de producción recomendada:**

```yaml
# docker-compose.prod.yml
services:
  kong-database:
    # NO exponer PostgreSQL fuera del contenedor
    ports: []  # Eliminar exposición del puerto 5432

  kong:
    ports:
      # Exponer solo proxy
      - "8000:8000"
      - "8443:8443"
      # Admin API solo en localhost
      - "127.0.0.1:8001:8001"

  konga:
    ports:
      # Konga solo en localhost o VPN
      - "127.0.0.1:1337:1337"
```

### 2. Usar Reverse Proxy

Colocar Kong detrás de un reverse proxy (Nginx, HAProxy) o Load Balancer para:

- Terminación SSL/TLS
- Rate limiting adicional
- WAF (Web Application Firewall)
- DDoS protection

### 3. Firewall y Reglas de Red

```bash
# Ejemplo con UFW
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw deny 8001/tcp   # Admin API (usar VPN o SSH tunnel)
sudo ufw deny 5432/tcp   # PostgreSQL
sudo ufw deny 1337/tcp   # Konga (usar VPN o SSH tunnel)
```

### 4. TLS/SSL

**Configurar certificados SSL en Kong:**

```bash
# Crear certificado (producción: usar Let's Encrypt)
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes

# Configurar en Kong via Admin API
curl -i -X POST http://localhost:8001/certificates \
  -F "cert=@cert.pem" \
  -F "key=@key.pem"
```

**Variables para SSL:**

```bash
# En .env
KONG_SSL_CERT=/path/to/cert.pem
KONG_SSL_CERT_KEY=/path/to/key.pem
```

## Configuración de Kong

### 1. Habilitar Autenticación

**NUNCA** exponer APIs sin autenticación en producción.

**Plugins recomendados:**

```bash
# Key Authentication
curl -X POST http://localhost:8001/routes/{route}/plugins \
  --data "name=key-auth"

# JWT
curl -X POST http://localhost:8001/routes/{route}/plugins \
  --data "name=jwt"

# OAuth 2.0
curl -X POST http://localhost:8001/routes/{route}/plugins \
  --data "name=oauth2"
```

### 2. Rate Limiting

Proteger contra abuso y DDoS:

```bash
curl -X POST http://localhost:8001/services/{service}/plugins \
  --data "name=rate-limiting" \
  --data "config.minute=100" \
  --data "config.hour=10000"
```

### 3. IP Restriction

Limitar acceso por IP:

```bash
curl -X POST http://localhost:8001/routes/{route}/plugins \
  --data "name=ip-restriction" \
  --data "config.allow=10.0.0.0/8" \
  --data "config.allow=192.168.0.0/16"
```

### 4. CORS Seguro

Configurar CORS solo para orígenes conocidos:

```bash
curl -X POST http://localhost:8001/services/{service}/plugins \
  --data "name=cors" \
  --data "config.origins=https://example.com" \
  --data "config.methods=GET,POST" \
  --data "config.credentials=true"
```

### 5. Request Size Limiting

Prevenir ataques de payload excesivo:

```bash
curl -X POST http://localhost:8001/services/{service}/plugins \
  --data "name=request-size-limiting" \
  --data "config.allowed_payload_size=10"
```

## Hardening de Contenedores

### 1. Ejecutar como Usuario No-Root

```dockerfile
# Ejemplo en Dockerfile personalizado
USER kong
```

### 2. Escaneo de Vulnerabilidades

```bash
# Usando Trivy
trivy image kong:3.6.1
trivy image postgres:15-alpine
trivy image pantsel/konga:0.14.9
```

### 3. Límites de Recursos

Ya configurados en `docker-compose.yml`:

```yaml
deploy:
  resources:
    limits:
      cpus: '2.0'
      memory: 1G
```

### 4. Read-Only Filesystem

Para mayor seguridad:

```yaml
services:
  kong:
    read_only: true
    tmpfs:
      - /tmp
      - /var/run
```

## Monitoreo y Auditoría

### 1. Logging Centralizado

Enviar logs a un sistema centralizado:

- ELK Stack (Elasticsearch, Logstash, Kibana)
- Graylog
- Splunk
- CloudWatch / Stackdriver

```yaml
services:
  kong:
    logging:
      driver: "syslog"
      options:
        syslog-address: "tcp://logserver:514"
```

### 2. Auditoría de Admin API

Usar el plugin `file-log` para auditoría:

```bash
curl -X POST http://localhost:8001/plugins \
  --data "name=file-log" \
  --data "config.path=/var/log/kong/admin-audit.log"
```

### 3. Monitoreo de Métricas

Configurar Prometheus + Grafana:

```bash
# Plugin Prometheus
curl -X POST http://localhost:8001/plugins \
  --data "name=prometheus"
```

### 4. Alertas

Configurar alertas para:

- Intentos de autenticación fallidos
- Rate limit excedido
- Errores 5xx
- Uso de recursos crítico
- Intentos de acceso no autorizados

## Actualizaciones y Parches

### 1. Política de Actualizaciones

- **Críticas**: Aplicar inmediatamente
- **Seguridad**: Dentro de 7 días
- **Menores**: Mensualmente en ventana de mantenimiento

### 2. Proceso de Actualización

```bash
# 1. Backup
make backup

# 2. Actualizar imágenes
docker-compose pull

# 3. Aplicar en staging primero
docker-compose -f docker-compose.yml -f docker-compose.staging.yml up -d

# 4. Verificar
make test

# 5. Aplicar en producción
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

### 3. Suscripciones de Seguridad

- [Kong Security Updates](https://konghq.com/security-updates)
- CVE Databases
- Docker Security Advisories

## Respuesta a Incidentes

### 1. Plan de Respuesta

**Pasos en caso de brecha de seguridad:**

1. **Contención**: Aislar sistemas comprometidos
2. **Evaluación**: Determinar alcance del incidente
3. **Erradicación**: Eliminar amenaza
4. **Recuperación**: Restaurar servicios
5. **Lecciones aprendidas**: Documentar y mejorar

### 2. Contactos de Emergencia

Mantener lista actualizada de:

- Equipo de seguridad
- Administradores de sistemas
- Contactos de proveedores
- Autoridades relevantes

### 3. Backup y Recuperación

```bash
# Backup automático diario
0 2 * * * /path/to/scripts/backup.sh

# Probar restauración mensualmente
make restore FILE=backups/latest.sql.gz
```

## Checklist de Seguridad

### Antes de Producción

- [ ] Cambiar todas las credenciales por defecto
- [ ] Habilitar HTTPS/TLS
- [ ] Configurar firewall
- [ ] Restringir acceso a Admin API
- [ ] Deshabilitar registro público de Konga
- [ ] Configurar autenticación en todas las rutas
- [ ] Habilitar rate limiting
- [ ] Configurar backups automáticos
- [ ] Escanear vulnerabilidades en imágenes
- [ ] Configurar logging centralizado
- [ ] Establecer monitoreo y alertas
- [ ] Documentar plan de respuesta a incidentes
- [ ] Probar proceso de restauración

### Mantenimiento Continuo

- [ ] Revisar logs de seguridad semanalmente
- [ ] Actualizar software mensualmente
- [ ] Rotar credenciales según política
- [ ] Revisar configuración de plugins
- [ ] Auditar usuarios y permisos
- [ ] Probar backups y restauración
- [ ] Revisar métricas de seguridad
- [ ] Mantener documentación actualizada

## Recursos Adicionales

- [Kong Security Best Practices](https://docs.konghq.com/gateway/latest/production/deployment-topologies/security/)
- [OWASP API Security](https://owasp.org/www-project-api-security/)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)
- [PostgreSQL Security](https://www.postgresql.org/docs/current/security.html)

## Reporte de Vulnerabilidades

Si encuentras una vulnerabilidad de seguridad en esta configuración, por favor:

1. **NO** abrir un issue público
2. Contactar a los mantenedores directamente
3. Proporcionar detalles técnicos
4. Permitir tiempo razonable para corrección antes de divulgación pública

---

**Última actualización**: 2024
**Versión**: 1.0
