# Guía de Instalación

Esta guía te ayudará a instalar y configurar PicapRh en tu entorno local.

## Prerrequisitos

Antes de comenzar, asegúrate de tener instalado:

- **Ruby** 3.4.5 o superior
- **Rails** 8.0.4 o superior
- **Node.js** 18.x o superior
- **PostgreSQL** 14.x o superior (producción)
- **Git** 2.x o superior

## Instalación de Dependencias del Sistema

### macOS

```bash
# Instalar Homebrew (si no está instalado)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Instalar Ruby con rbenv
brew install rbenv ruby-build
rbenv install 3.4.5
rbenv global 3.4.5

# Instalar PostgreSQL
brew install postgresql@14
brew services start postgresql@14

# Instalar Node.js
brew install node
```

### Ubuntu/Debian

```bash
# Actualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar dependencias
sudo apt install -y git curl libssl-dev libreadline-dev zlib1g-dev \
  autoconf bison build-essential libyaml-dev libreadline-dev \
  libncurses5-dev libffi-dev libgdbm-dev

# Instalar rbenv
curl -fsSL https://github.com/rbenv/rbenv-installer/raw/HEAD/bin/rbenv-installer | bash
rbenv install 3.4.5
rbenv global 3.4.5

# Instalar PostgreSQL
sudo apt install -y postgresql postgresql-contrib libpq-dev
sudo service postgresql start

# Instalar Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs
```

## Configuración del Proyecto

### 1. Clonar el Repositorio

```bash
git clone https://github.com/hectronix2005/VacacionesRH.git
cd VacacionesRH
```

### 2. Instalar Dependencias de Ruby

```bash
# Instalar bundler
gem install bundler

# Instalar gemas del proyecto
bundle install
```

### 3. Configurar Base de Datos

#### Desarrollo (SQLite - Por defecto)

```bash
# Crear y migrar base de datos
rails db:create
rails db:migrate
rails db:seed
```

#### Producción (PostgreSQL)

```bash
# Editar config/database.yml para PostgreSQL
# Luego ejecutar:
RAILS_ENV=production rails db:create
RAILS_ENV=production rails db:migrate
RAILS_ENV=production rails db:seed
```

### 4. Configurar Variables de Entorno

Crea un archivo `.env` en la raíz del proyecto:

```bash
# .env
DATABASE_URL=postgresql://usuario:password@localhost/picap_rh_production
SECRET_KEY_BASE=tu_secret_key_base_aqui
RAILS_ENV=production
RACK_ENV=production
```

Para generar un secret key:

```bash
rails secret
```

### 5. Compilar Assets

```bash
# Compilar TailwindCSS
rails tailwindcss:build

# Precompilar assets para producción
RAILS_ENV=production rails assets:precompile
```

## Iniciar el Servidor

### Desarrollo

```bash
# Usando bin/dev (recomendado - incluye Tailwind watch)
bin/dev

# O directamente con Rails
rails server
```

La aplicación estará disponible en: http://localhost:3000

### Producción

```bash
RAILS_ENV=production rails server -p 3000
```

## Verificar Instalación

### Ejecutar Tests

```bash
# Ejecutar suite completa de tests
bundle exec rspec

# Ejecutar tests específicos
bundle exec rspec spec/models
bundle exec rspec spec/requests
```

### Verificar Linter

```bash
# Ejecutar Rubocop
bundle exec rubocop

# Autofix problemas
bundle exec rubocop -a
```

### Escaneo de Seguridad

```bash
# Ejecutar Brakeman
bundle exec brakeman

# Auditar dependencias JavaScript
bin/importmap audit
```

## Credenciales de Prueba

Después de ejecutar `rails db:seed`, puedes iniciar sesión con:

### Colombia

- **HR**: 12345678 / password123
- **Líder**: 87654321 / password123
- **Empleado**: 11223344 / password123

### México

- **HR**: CURP123456 / password123
- **Líder**: CURP789012 / password123
- **Empleado**: CURP345678 / password123

## Problemas Comunes

### Error: Cannot find module

```bash
# Reinstalar dependencias
rm -rf node_modules
npm install
```

### Error: Database does not exist

```bash
# Recrear base de datos
rails db:drop db:create db:migrate db:seed
```

### Error: TailwindCSS no compila

```bash
# Limpiar y recompilar
rails tailwindcss:clobber
rails tailwindcss:build
```

### Error: Bundler version mismatch

```bash
# Actualizar bundler
gem install bundler
bundle update --bundler
```

## Próximos Pasos

- [Guía de Usuario](user-guide.md)
- [Arquitectura del Sistema](architecture.md)
- [Deployment a Producción](deployment.md)

## Soporte

Si encuentras problemas durante la instalación:
1. Revisa los [Issues en GitHub](https://github.com/hectronix2005/VacacionesRH/issues)
2. Crea un nuevo issue con detalles del error
3. Consulta los logs en `log/development.log`
