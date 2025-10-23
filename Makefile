.PHONY: help up down restart logs logs-kong logs-konga logs-db status health clean backup restore build rebuild ps shell-kong shell-db test

# Variables
COMPOSE := docker-compose
COMPOSE_FILE := docker-compose.yml
ENV_FILE := .env

# Colores para output
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

help: ## Mostrar este mensaje de ayuda
	@echo "$(GREEN)Kong API Gateway + Konga - Comandos Disponibles$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}'

up: ## Iniciar todos los servicios
	@echo "$(GREEN)Iniciando servicios...$(NC)"
	$(COMPOSE) up -d
	@echo "$(GREEN)Servicios iniciados correctamente$(NC)"
	@$(MAKE) status

down: ## Detener todos los servicios
	@echo "$(YELLOW)Deteniendo servicios...$(NC)"
	$(COMPOSE) down
	@echo "$(GREEN)Servicios detenidos$(NC)"

restart: ## Reiniciar todos los servicios
	@echo "$(YELLOW)Reiniciando servicios...$(NC)"
	$(COMPOSE) restart
	@echo "$(GREEN)Servicios reiniciados$(NC)"

build: ## Construir las imágenes
	@echo "$(GREEN)Construyendo imágenes...$(NC)"
	$(COMPOSE) build

rebuild: ## Reconstruir y reiniciar todos los servicios
	@echo "$(YELLOW)Reconstruyendo servicios...$(NC)"
	$(COMPOSE) down
	$(COMPOSE) up -d --build
	@echo "$(GREEN)Servicios reconstruidos e iniciados$(NC)"

logs: ## Ver logs de todos los servicios
	$(COMPOSE) logs -f

logs-kong: ## Ver logs de Kong
	$(COMPOSE) logs -f kong

logs-konga: ## Ver logs de Konga
	$(COMPOSE) logs -f konga

logs-db: ## Ver logs de PostgreSQL
	$(COMPOSE) logs -f kong-database

status: ## Ver estado de los servicios
	@echo "$(GREEN)Estado de los servicios:$(NC)"
	@$(COMPOSE) ps

ps: status ## Alias para status

health: ## Verificar salud de los servicios
	@echo "$(GREEN)Verificando salud de los servicios...$(NC)"
	@echo ""
	@echo "$(YELLOW)Kong Gateway:$(NC)"
	@curl -s http://localhost:8001/status | jq '.' || echo "$(RED)Kong no responde$(NC)"
	@echo ""
	@echo "$(YELLOW)PostgreSQL:$(NC)"
	@docker exec kong-database pg_isready -U kong || echo "$(RED)PostgreSQL no responde$(NC)"
	@echo ""
	@echo "$(YELLOW)Konga:$(NC)"
	@curl -s -o /dev/null -w "HTTP Status: %{http_code}\n" http://localhost:1337 || echo "$(RED)Konga no responde$(NC)"

clean: ## Detener y eliminar todos los contenedores, volúmenes y redes
	@echo "$(RED)ADVERTENCIA: Esto eliminará todos los datos!$(NC)"
	@echo -n "¿Estás seguro? [y/N] " && read ans && [ $${ans:-N} = y ]
	$(COMPOSE) down -v
	@echo "$(GREEN)Limpieza completa realizada$(NC)"

backup: ## Crear backup de la base de datos
	@echo "$(GREEN)Creando backup de la base de datos...$(NC)"
	@mkdir -p backups
	@docker exec kong-database pg_dump -U kong kong > backups/kong-backup-$$(date +%Y%m%d-%H%M%S).sql
	@echo "$(GREEN)Backup creado en backups/$(NC)"
	@ls -lh backups/ | tail -n 1

restore: ## Restaurar backup de la base de datos (uso: make restore FILE=backup.sql)
	@if [ -z "$(FILE)" ]; then \
		echo "$(RED)Error: Especifica el archivo con FILE=nombre.sql$(NC)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)Restaurando backup desde $(FILE)...$(NC)"
	@docker exec -i kong-database psql -U kong -d kong < $(FILE)
	@echo "$(GREEN)Backup restaurado correctamente$(NC)"

shell-kong: ## Abrir shell en el contenedor de Kong
	@docker exec -it kong /bin/sh

shell-db: ## Abrir psql en PostgreSQL
	@docker exec -it kong-database psql -U kong -d kong

shell-konga: ## Abrir shell en el contenedor de Konga
	@docker exec -it konga /bin/sh

test: ## Ejecutar pruebas básicas del stack
	@echo "$(GREEN)Ejecutando pruebas básicas...$(NC)"
	@echo ""
	@echo "$(YELLOW)Test 1: Kong Admin API$(NC)"
	@curl -s -f http://localhost:8001 > /dev/null && echo "$(GREEN)✓ Kong Admin API respondiendo$(NC)" || echo "$(RED)✗ Kong Admin API no responde$(NC)"
	@echo ""
	@echo "$(YELLOW)Test 2: Kong Proxy$(NC)"
	@curl -s -f http://localhost:8000 > /dev/null && echo "$(GREEN)✓ Kong Proxy respondiendo$(NC)" || echo "$(YELLOW)⚠ Kong Proxy sin rutas configuradas (normal)$(NC)"
	@echo ""
	@echo "$(YELLOW)Test 3: Konga UI$(NC)"
	@curl -s -f http://localhost:1337 > /dev/null && echo "$(GREEN)✓ Konga UI respondiendo$(NC)" || echo "$(RED)✗ Konga UI no responde$(NC)"
	@echo ""
	@echo "$(YELLOW)Test 4: PostgreSQL$(NC)"
	@docker exec kong-database pg_isready -U kong > /dev/null 2>&1 && echo "$(GREEN)✓ PostgreSQL saludable$(NC)" || echo "$(RED)✗ PostgreSQL no responde$(NC)"

init: ## Inicializar el proyecto (primera vez)
	@echo "$(GREEN)Inicializando proyecto...$(NC)"
	@if [ ! -f $(ENV_FILE) ]; then \
		echo "$(YELLOW)Creando archivo .env desde .env.example...$(NC)"; \
		cp .env.example $(ENV_FILE); \
		echo "$(YELLOW)⚠ IMPORTANTE: Edita .env y cambia las passwords por defecto$(NC)"; \
	else \
		echo "$(YELLOW)El archivo .env ya existe$(NC)"; \
	fi
	@$(MAKE) up
	@echo ""
	@echo "$(GREEN)Proyecto inicializado correctamente!$(NC)"
	@echo "$(YELLOW)Accede a Konga en: http://localhost:1337$(NC)"

info: ## Mostrar información del entorno
	@echo "$(GREEN)Información del Entorno Kong$(NC)"
	@echo ""
	@echo "$(YELLOW)Versiones:$(NC)"
	@echo "  Kong:       $$(docker exec kong kong version 2>/dev/null || echo 'no disponible')"
	@echo "  PostgreSQL: $$(docker exec kong-database psql --version 2>/dev/null | head -n1 || echo 'no disponible')"
	@echo ""
	@echo "$(YELLOW)Endpoints:$(NC)"
	@echo "  Konga UI:          http://localhost:1337"
	@echo "  Kong Admin API:    http://localhost:8001"
	@echo "  Kong Proxy:        http://localhost:8000"
	@echo "  Kong Proxy (SSL):  https://localhost:8443"
	@echo "  Kong Status:       http://localhost:8100"
	@echo "  PostgreSQL:        localhost:5432"
	@echo ""
	@echo "$(YELLOW)Estado de Contenedores:$(NC)"
	@$(COMPOSE) ps

dev: ## Modo desarrollo con logs en vivo
	@echo "$(GREEN)Iniciando en modo desarrollo...$(NC)"
	$(COMPOSE) up

prod: ## Iniciar con configuración de producción
	@echo "$(GREEN)Iniciando en modo producción...$(NC)"
	@if [ -f docker-compose.prod.yml ]; then \
		$(COMPOSE) -f $(COMPOSE_FILE) -f docker-compose.prod.yml up -d; \
	else \
		echo "$(YELLOW)docker-compose.prod.yml no encontrado, usando configuración estándar$(NC)"; \
		$(COMPOSE) up -d; \
	fi

update: ## Actualizar imágenes a las últimas versiones
	@echo "$(GREEN)Actualizando imágenes...$(NC)"
	$(COMPOSE) pull
	@echo "$(GREEN)Imágenes actualizadas. Ejecuta 'make rebuild' para aplicar cambios$(NC)"
