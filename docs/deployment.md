# Guía de Deployment

Esta guía cubre el deployment de PicapRh a diferentes plataformas de producción.

## Deployment a Heroku

### Prerrequisitos

1. Cuenta en [Heroku](https://heroku.com)
2. Heroku CLI instalado
3. Git configurado

### Instalación de Heroku CLI

```bash
# macOS
brew tap heroku/brew && brew install heroku

# Ubuntu/Debian
curl https://cli-assets.heroku.com/install.sh | sh

# Verificar instalación
heroku --version
```

### Login a Heroku

```bash
heroku login
```

### Crear Aplicación

```bash
# Crear app (si no existe)
heroku create vacacionesrh

# O conectar a app existente
heroku git:remote -a vacacionesrh
```

### Configurar Add-ons

```bash
# PostgreSQL
heroku addons:create heroku-postgresql:mini

# Redis (opcional, para Solid Queue en producción)
heroku addons:create heroku-redis:mini
```

### Configurar Variables de Entorno

```bash
# Generar y configurar secret key
heroku config:set SECRET_KEY_BASE=$(rails secret)

# Configurar Rails
heroku config:set RAILS_ENV=production
heroku config:set RACK_ENV=production
heroku config:set RAILS_LOG_TO_STDOUT=enabled
heroku config:set RAILS_SERVE_STATIC_FILES=true

# Ver configuración
heroku config
```

### Deploy

```bash
# Push a Heroku
git push heroku main

# Ejecutar migraciones
heroku run rails db:migrate

# Seed inicial (solo primera vez)
heroku run rails db:seed

# Abrir aplicación
heroku open
```

### Logs y Monitoreo

```bash
# Ver logs en tiempo real
heroku logs --tail

# Ver logs específicos
heroku logs --tail --source app

# Información de la app
heroku ps
heroku releases
```

### Mantenimiento

```bash
# Ejecutar consola de Rails
heroku run rails console

# Ejecutar migraciones
heroku run rails db:migrate

# Rollback de migración
heroku run rails db:rollback

# Reset de base de datos (CUIDADO)
heroku pg:reset DATABASE_URL --confirm vacacionesrh
heroku run rails db:migrate db:seed
```

## Deployment a DigitalOcean (Kamal)

El proyecto incluye configuración de Kamal para deployment a DigitalOcean.

### Prerrequisitos

1. Droplet de DigitalOcean
2. Docker instalado localmente
3. Kamal CLI instalado

### Instalación de Kamal

```bash
gem install kamal
```

### Configurar Kamal

Edita `config/deploy.yml`:

```yaml
service: picap_rh
image: hectronix2005/picap_rh

servers:
  web:
    - YOUR_SERVER_IP

registry:
  username: hectronix2005
  password:
    - KAMAL_REGISTRY_PASSWORD

env:
  secret:
    - RAILS_MASTER_KEY
  clear:
    RAILS_ENV: production
```

### Setup y Deploy

```bash
# Setup inicial (primera vez)
kamal setup

# Deploy
kamal deploy

# Ver logs
kamal app logs

# Ejecutar comandos
kamal app exec 'rails db:migrate'
kamal app exec 'rails console'
```

## Deployment a Fly.io

### Instalación de Fly CLI

```bash
# macOS/Linux
curl -L https://fly.io/install.sh | sh

# Login
fly auth login
```

### Launch App

```bash
# Crear y configurar app
fly launch

# Deploy
fly deploy

# Ver logs
fly logs

# Abrir app
fly open
```

## Configuración de Producción

### Variables de Entorno Requeridas

```bash
SECRET_KEY_BASE=your_secret_key_base
DATABASE_URL=postgresql://user:pass@host:5432/dbname
RAILS_ENV=production
RACK_ENV=production
RAILS_LOG_TO_STDOUT=enabled
RAILS_SERVE_STATIC_FILES=true
```

### Configuración de Base de Datos

Para PostgreSQL en producción, actualiza `config/database.yml`:

```yaml
production:
  <<: *default
  url: <%= ENV['DATABASE_URL'] %>
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
```

### Compilación de Assets

En producción, los assets deben estar precompilados:

```bash
RAILS_ENV=production rails assets:precompile
RAILS_ENV=production rails tailwindcss:build
```

## Health Checks

### Endpoint de Health

El sistema expone un endpoint de health en `/up` para verificar:
- Conectividad de base de datos
- Disponibilidad de caché
- Estado de Solid Queue

```bash
curl https://vacacionesrh.herokuapp.com/up
```

## Backup y Recuperación

### Backup de Base de Datos (Heroku)

```bash
# Crear backup
heroku pg:backups:capture

# Listar backups
heroku pg:backups

# Descargar backup
heroku pg:backups:download

# Restaurar backup
heroku pg:backups:restore b001 DATABASE_URL
```

### Backup de Base de Datos (Manual)

```bash
# Exportar
pg_dump -U usuario -h host -d database > backup.sql

# Importar
psql -U usuario -h host -d database < backup.sql
```

## SSL/TLS

### Heroku

SSL está incluido automáticamente con Heroku.

### Custom Domain

```bash
# Agregar dominio
heroku domains:add www.tudominio.com

# Configurar SSL automático
heroku certs:auto:enable
```

## Performance Optimization

### Configurar Cache

```bash
# Heroku Redis
heroku addons:create heroku-redis:mini

# Configurar en producción
heroku config:set REDIS_URL=redis://...
```

### Configurar CDN

Para servir assets estáticos más rápido, considera usar:
- Cloudflare
- AWS CloudFront
- Fastly

## Monitoreo

### New Relic (Incluido)

El proyecto incluye configuración de New Relic. Configura:

```bash
heroku config:set NEW_RELIC_LICENSE_KEY=your_key
heroku config:set NEW_RELIC_APP_NAME="PicapRh Production"
```

### Otros Servicios

- Sentry (Error tracking)
- Scout APM (Performance monitoring)
- Papertrail (Log management)

## Troubleshooting

### Error: Database Connection

```bash
# Verificar DATABASE_URL
heroku config:get DATABASE_URL

# Reiniciar app
heroku restart
```

### Error: Assets No Cargan

```bash
# Verificar configuración
heroku config:get RAILS_SERVE_STATIC_FILES

# Recompilar assets
heroku run rails assets:precompile
```

### Error: Workers No Procesan Jobs

```bash
# Verificar dynos
heroku ps

# Escalar workers
heroku ps:scale jobs=1
```

## Costos Estimados

### Heroku

- Dyno Basic: $7/mes
- PostgreSQL Mini: $5/mes
- Redis Mini: $3/mes
- **Total**: ~$15/mes

### DigitalOcean

- Droplet Basic: $6/mes
- Managed PostgreSQL: $15/mes
- **Total**: ~$21/mes

## Próximos Pasos

- [Configurar Monitoreo](monitoring.md)
- [Configurar Backups Automáticos](backups.md)
- [Scaling Guide](scaling.md)
