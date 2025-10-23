# Guía de Contribución

¡Gracias por tu interés en contribuir a este proyecto! Esta guía te ayudará a entender cómo puedes colaborar.

## Tabla de Contenidos

- [Código de Conducta](#código-de-conducta)
- [¿Cómo Puedo Contribuir?](#cómo-puedo-contribuir)
- [Proceso de Desarrollo](#proceso-de-desarrollo)
- [Guías de Estilo](#guías-de-estilo)
- [Reportar Bugs](#reportar-bugs)
- [Sugerir Mejoras](#sugerir-mejoras)
- [Pull Requests](#pull-requests)

## Código de Conducta

Este proyecto se adhiere a un código de conducta profesional. Al participar, se espera que mantengas un ambiente respetuoso y constructivo.

### Nuestros Estándares

- Usar lenguaje acogedor e inclusivo
- Respetar puntos de vista y experiencias diferentes
- Aceptar críticas constructivas con gracia
- Enfocarse en lo que es mejor para la comunidad
- Mostrar empatía hacia otros miembros de la comunidad

## ¿Cómo Puedo Contribuir?

### Reportar Bugs

Si encuentras un bug, por favor crea un issue incluyendo:

1. **Descripción clara del problema**
2. **Pasos para reproducir**:
   ```
   1. Ejecutar '...'
   2. Ver error en '...'
   3. Error ocurre
   ```
3. **Comportamiento esperado**: Qué esperabas que sucediera
4. **Comportamiento actual**: Qué sucedió en realidad
5. **Entorno**:
   - OS: [e.g. Ubuntu 22.04]
   - Docker version: [e.g. 24.0.6]
   - Docker Compose version: [e.g. 2.21.0]
   - Kong version: [e.g. 3.6.1]
6. **Logs relevantes**: Si es posible
7. **Screenshots**: Si aplica

### Sugerir Mejoras

Las sugerencias de mejoras son bienvenidas. Por favor:

1. Verifica que la mejora no haya sido sugerida antes
2. Proporciona un caso de uso claro
3. Explica por qué sería útil para la mayoría de usuarios
4. Si es posible, proporciona ejemplos de implementación

### Contribuir con Código

1. **Configuraciones de Kong**: Scripts de ejemplo, configuraciones de plugins
2. **Documentación**: Mejoras a README, guías, tutoriales
3. **Scripts**: Herramientas de utilidad, automatización
4. **Docker**: Mejoras a docker-compose, Dockerfiles
5. **Seguridad**: Mejoras a configuraciones de seguridad

## Proceso de Desarrollo

### 1. Fork y Clone

```bash
# Fork el repositorio en GitHub, luego:
git clone https://github.com/TU-USUARIO/docker-kongapigateway-konga.git
cd docker-kongapigateway-konga
```

### 2. Crear una Rama

```bash
git checkout -b feature/mi-nueva-caracteristica
# o
git checkout -b fix/arreglo-de-bug
```

**Nomenclatura de ramas:**
- `feature/nombre-descriptivo` - Para nuevas características
- `fix/nombre-descriptivo` - Para correcciones de bugs
- `docs/nombre-descriptivo` - Para cambios en documentación
- `refactor/nombre-descriptivo` - Para refactorizaciones

### 3. Configurar el Entorno

```bash
# Copiar variables de entorno
cp .env.example .env

# Iniciar el stack
make init
# o
docker-compose up -d

# Verificar estado
make health
```

### 4. Realizar Cambios

- Escribe código claro y mantenible
- Sigue las guías de estilo del proyecto
- Comenta código complejo cuando sea necesario
- Actualiza documentación si es relevante

### 5. Probar Cambios

```bash
# Probar el stack completo
make test

# Verificar salud de servicios
make health

# Ver logs
make logs
```

### 6. Commit

Usa commits descriptivos siguiendo [Conventional Commits](https://www.conventionalcommits.org/):

```bash
git add .
git commit -m "feat: agregar configuración de rate limiting para microservicios"
```

**Tipos de commit:**
- `feat`: Nueva característica
- `fix`: Corrección de bug
- `docs`: Cambios en documentación
- `style`: Formato, punto y coma faltantes, etc.
- `refactor`: Refactorización de código
- `test`: Agregar o corregir tests
- `chore`: Tareas de mantenimiento

**Ejemplos:**
```
feat: agregar ejemplo de JWT authentication
fix: corregir healthcheck de Konga
docs: actualizar guía de instalación
chore: actualizar versión de Kong a 3.6.1
```

### 7. Push y Pull Request

```bash
git push origin feature/mi-nueva-caracteristica
```

Luego crea un Pull Request en GitHub.

## Guías de Estilo

### Bash Scripts

```bash
#!/bin/bash

##
## Descripción breve del script
##

set -e

# Colores
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Variables en MAYÚSCULAS
VARIABLE_NAME="${ENV_VAR:-default_value}"

# Funciones con snake_case
function_name() {
    local param=$1
    echo "mensaje"
}
```

### YAML (docker-compose)

```yaml
# Comentarios descriptivos
services:
  service-name:
    image: nombre:version
    container_name: nombre-descriptivo
    # Agrupar configuraciones relacionadas
    environment:
      VAR_ONE: value
      VAR_TWO: value
    # Usar labels para metadata
    labels:
      com.proyecto.description: "Descripción"
```

### Markdown

- Usar encabezados apropiados (H1 para título, H2 para secciones)
- Incluir tabla de contenidos en documentos largos
- Usar bloques de código con el lenguaje especificado
- Incluir ejemplos prácticos
- Mantener líneas de máximo 120 caracteres cuando sea posible

### Variables de Entorno

```bash
# Usar valores por defecto sensatos
VARIABLE_NAME=${ENV_VAR:-default_value}

# Documentar variables en .env.example
# Comentario descriptivo de la variable
VARIABLE_NAME=valor_ejemplo
```

## Pull Requests

### Antes de Enviar

- [ ] El código sigue las guías de estilo del proyecto
- [ ] Has probado tus cambios localmente
- [ ] Has actualizado la documentación relevante
- [ ] Has agregado ejemplos si es aplicable
- [ ] Los cambios no rompen funcionalidad existente
- [ ] Has verificado que no hay conflictos con main

### Descripción del PR

Usa esta plantilla:

```markdown
## Descripción
Descripción clara de los cambios

## Tipo de Cambio
- [ ] Bug fix
- [ ] Nueva característica
- [ ] Cambio que rompe compatibilidad
- [ ] Documentación

## ¿Cómo se ha probado?
Describe las pruebas realizadas

## Checklist
- [ ] Mi código sigue las guías de estilo
- [ ] He revisado mi propio código
- [ ] He comentado código complejo
- [ ] He actualizado la documentación
- [ ] Mis cambios no generan nuevas advertencias
- [ ] He probado que funciona correctamente
```

### Revisión

- Responde a los comentarios de manera constructiva
- Realiza los cambios solicitados si son razonables
- Solicita aclaraciones si algo no está claro
- Sé paciente durante el proceso de revisión

## Áreas Específicas de Contribución

### Ejemplos de Configuración

```bash
examples/
├── plugins/
│   └── nuevo-plugin.sh        # Script de ejemplo
├── services/
│   └── nuevo-servicio.sh      # Configuración de servicio
└── README.md                   # Actualizar con nuevo ejemplo
```

### Documentación

- README.md: Guía principal
- SECURITY.md: Mejores prácticas de seguridad
- CLAUDE.md: Contexto para Claude Code
- examples/: Ejemplos prácticos

### Scripts de Utilidad

```bash
scripts/
├── backup.sh          # Respaldo de datos
├── restore.sh         # Restauración
├── health-check.sh    # Verificación de salud
└── tu-script.sh       # Nuevo script útil
```

### Mejoras al Stack

- Optimizaciones de docker-compose
- Nuevos healthchecks
- Configuraciones de producción
- Automatización con Makefile

## Recursos

- [Documentación de Kong](https://docs.konghq.com/)
- [Docker Compose Reference](https://docs.docker.com/compose/compose-file/)
- [Bash Style Guide](https://google.github.io/styleguide/shellguide.html)
- [Conventional Commits](https://www.conventionalcommits.org/)

## Preguntas

Si tienes preguntas, puedes:

1. Revisar la documentación existente
2. Buscar en issues cerrados
3. Crear un nuevo issue con la etiqueta "question"

## Reconocimientos

Todos los contribuidores serán reconocidos. Tu contribución, sin importar el tamaño, es valorada y apreciada.

---

¡Gracias por contribuir! 🙌
