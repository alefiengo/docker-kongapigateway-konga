# Kong API Gateway + Konga

[![Kong](https://img.shields.io/badge/Kong-3.6.1-003459?style=flat-square&logo=kong)](https://konghq.com/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-336791?style=flat-square&logo=postgresql&logoColor=white)](https://www.postgresql.org/)
[![Konga](https://img.shields.io/badge/Konga-0.14.9-44B3E4?style=flat-square)](https://github.com/pantsel/konga)
[![Docker](https://img.shields.io/badge/Docker-Compose-2496ED?style=flat-square&logo=docker&logoColor=white)](https://docs.docker.com/compose/)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

Stack completo de Kong API Gateway (OSS) con interfaz de administración Konga y base de datos PostgreSQL, orquestado mediante Docker Compose.

## Descripción

Este proyecto proporciona un entorno listo para usar de Kong API Gateway con:

- **Kong Gateway 3.6.1**: API Gateway de código abierto para gestionar, monitorear y asegurar APIs
- **PostgreSQL 15**: Base de datos para almacenar la configuración de Kong
- **Konga 0.14.9**: Interfaz web de administración para Kong
- **Arquitectura en contenedores**: Todos los servicios aislados y orquestados con Docker Compose

## Arquitectura

El stack está compuesto por cuatro servicios:

```
┌─────────────┐
│   Konga     │ Puerto 1337 - Interfaz Web
└──────┬──────┘
       │
┌──────▼──────┐
│    Kong     │ Puertos 8000, 8443, 8001, 8100
└──────┬──────┘
       │
┌──────▼──────────┐
│   PostgreSQL    │ Puerto 5432
└─────────────────┘
```

### Servicios

- **kong-database**: PostgreSQL 15 con healthchecks y persistencia de datos
- **kong-migrations**: Servicio de inicialización para crear el esquema de base de datos
- **kong**: Kong Gateway con Admin API, Status API y Proxy
- **konga**: Interfaz de administración web conectada a Kong

## Requisitos Previos

- [Docker Engine](https://docs.docker.com/engine/install/) 20.10 o superior
- [Docker Compose](https://docs.docker.com/compose/install/) 2.0 o superior
- Puertos disponibles: 1337, 5432, 8000, 8001, 8100, 8443

## Instalación

### 1. Clonar el repositorio

```bash
git clone https://github.com/alefiengo/docker-kongapigateway-konga
cd docker-kongapigateway-konga
```

### 2. Configurar variables de entorno

Crear un archivo `.env` basado en el ejemplo proporcionado:

```bash
cp .env.example .env
```

Editar `.env` y modificar las variables según sea necesario:

```bash
# Cambiar passwords por defecto
POSTGRES_PASSWORD=tu_password_seguro
KONG_PG_PASSWORD=tu_password_seguro
KONGA_TOKEN_SECRET=tu_token_secreto_largo
```

### 3. Iniciar el stack

```bash
docker-compose up -d --build
```

Este comando:
- Construye las imágenes si es necesario
- Crea la red `kong-net`
- Crea el volumen `kong_db_data`
- Inicia los contenedores en el orden correcto
- Ejecuta las migraciones de base de datos automáticamente

### 4. Verificar el estado

```bash
docker-compose ps
```

Todos los servicios deben estar en estado `Up` (healthy).

## Configuración Inicial de Konga

### Primer Acceso y Configuración

#### 1. Acceder a la interfaz web

Navegar a `http://localhost:1337` en el navegador.

#### 2. Crear cuenta de administrador

En la primera visita, Konga solicitará crear una cuenta de administrador. Completar el formulario de registro con:

- Nombre de usuario
- Correo electrónico
- Contraseña segura

#### 3. Autenticación

Iniciar sesión con las credenciales creadas en el paso anterior.

#### 4. Configurar conexión con Kong Gateway

Después de autenticarse, configurar la conexión entre Konga y Kong en la sección **"Connections"**:

**Parámetros de conexión:**
- **Name**: `Kong Local` (o cualquier identificador descriptivo)
- **Kong Admin URL**: `http://kong:8001`

> **Importante**: Usar `http://kong:8001` (nombre del servicio) en lugar de `http://localhost:8001`, ya que Konga se ejecuta dentro de la red Docker y debe acceder a Kong mediante el nombre del servicio.

Hacer clic en **"Create Connection"** para establecer la conexión.

Una vez completados estos pasos, Konga estará listo para administrar Kong Gateway.

## Uso

### Acceder a los servicios

| Servicio | URL | Descripción |
|----------|-----|-------------|
| Konga UI | http://localhost:1337 | Interfaz de administración |
| Kong Admin API | http://localhost:8001 | API de administración |
| Kong Proxy | http://localhost:8000 | Endpoint del API Gateway |
| Kong Proxy SSL | https://localhost:8443 | Endpoint seguro |
| Kong Status | http://localhost:8100 | Estado del gateway |
| PostgreSQL | localhost:5432 | Base de datos (usuario: kong) |

### Comandos útiles

**Ver logs en tiempo real:**
```bash
docker-compose logs -f
```

**Ver logs de un servicio específico:**
```bash
docker-compose logs -f kong
docker-compose logs -f konga
```

**Reiniciar un servicio:**
```bash
docker-compose restart kong
```

**Detener todos los servicios:**
```bash
docker-compose down
```

**Detener y eliminar volúmenes (¡cuidado, elimina datos!):**
```bash
docker-compose down -v
```

**Acceder a la base de datos:**
```bash
docker exec -it kong-database psql -U kong -d kong
```

**Verificar salud de Kong:**
```bash
curl http://localhost:8001/status
```

## Configuración Avanzada

### Variables de Entorno Principales

| Variable | Descripción | Valor por defecto |
|----------|-------------|-------------------|
| `POSTGRES_PASSWORD` | Password de PostgreSQL | `changeme` |
| `KONG_PG_PASSWORD` | Password de Kong para conectar a PostgreSQL | `${POSTGRES_PASSWORD}` |
| `KONGA_TOKEN_SECRET` | Secret para tokens JWT de Konga | `changeme` |
| `KONG_ADMIN_LISTEN` | Dirección de escucha del Admin API | `0.0.0.0:8001` |
| `KONG_PROXY_LISTEN` | Dirección de escucha del Proxy | `0.0.0.0:8000, 0.0.0.0:8443 ssl` |

### Personalización

Para personalizar la configuración, editar el archivo `.env` o crear un archivo `docker-compose.override.yml`.

## Solución de Problemas

### Los contenedores no inician correctamente

```bash
# Ver logs detallados
docker-compose logs

# Verificar estado de salud
docker-compose ps
```

### Error de conexión de Kong a la base de datos

1. Verificar que el contenedor de PostgreSQL esté healthy:
   ```bash
   docker-compose ps kong-database
   ```

2. Revisar las credenciales en el archivo `.env`

3. Reiniciar el stack:
   ```bash
   docker-compose down
   docker-compose up -d
   ```

### Konga no puede conectarse a Kong

Usar la URL interna `http://kong:8001` en lugar de `http://localhost:8001`. Los contenedores se comunican a través de la red `kong-net`.

### Resetear todo el entorno

```bash
docker-compose down -v
docker-compose up -d --build
```

## Persistencia de Datos

Los datos de PostgreSQL se almacenan en el volumen `kong_db_data`, que persiste entre reinicios del contenedor. Para hacer backup:

```bash
docker exec kong-database pg_dump -U kong kong > backup.sql
```

Para restaurar:

```bash
docker exec -i kong-database psql -U kong -d kong < backup.sql
```

## Seguridad

- **Cambiar passwords por defecto** en producción
- **No exponer puertos innecesarios** en entornos de producción
- **Usar HTTPS** para todas las conexiones en producción
- **Configurar rate limiting** en Kong para proteger tus APIs
- **Habilitar autenticación** en los endpoints de tus servicios

## Recursos Adicionales

- [Documentación oficial de Kong](https://docs.konghq.com/)
- [Repositorio de Konga](https://github.com/pantsel/konga)
- [Kong Admin API](https://docs.konghq.com/gateway/latest/admin-api/)
- [Plugins de Kong](https://docs.konghq.com/hub/)

## Licencia

Este proyecto utiliza componentes de código abierto bajo sus respectivas licencias.