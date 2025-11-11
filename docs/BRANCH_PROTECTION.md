# Configurar Protección de Rama Main

Para proteger la rama `main` y asegurar la calidad del código, sigue estos pasos:

## Acceder a Configuración de Branch Protection

1. Ve a tu repositorio: https://github.com/hectronix2005/VacacionesRH
2. Click en **Settings** (Configuración)
3. En el menú lateral, click en **Branches** (Ramas)
4. Click en **Add branch protection rule** (Agregar regla de protección de rama)

## Configuración Recomendada

### Branch name pattern
```
main
```

### Protections (Marcar estas opciones)

#### Require a pull request before merging
- ✅ **Require a pull request before merging**
  - ✅ Require approvals: **1**
  - ✅ Dismiss stale pull request approvals when new commits are pushed
  - ✅ Require review from Code Owners (opcional)

#### Require status checks to pass before merging
- ✅ **Require status checks to pass before merging**
  - ✅ Require branches to be up to date before merging
  - Buscar y seleccionar los siguientes checks:
    - ✅ `scan_ruby` (Brakeman security scan)
    - ✅ `scan_js` (JavaScript audit)
    - ✅ `lint` (Rubocop)
    - ✅ `test` (RSpec tests)

#### Require conversation resolution before merging
- ✅ **Require conversation resolution before merging**

#### Require signed commits (opcional pero recomendado)
- ⬜ Require signed commits

#### Require linear history
- ✅ **Require linear history**

#### Include administrators
- ⬜ Include administrators (permite a admins hacer push directo en emergencias)

#### Restrict who can push to matching branches (opcional)
- ⬜ Restrict pushes that create matching branches

#### Allow force pushes
- ❌ **NO marcar** (deshabilitar force push)

#### Allow deletions
- ❌ **NO marcar** (prevenir eliminación accidental)

## Resultado

Después de configurar estas reglas:

1. ✅ No se puede hacer push directo a `main`
2. ✅ Todos los cambios deben venir de Pull Requests
3. ✅ Los PRs requieren al menos 1 aprobación
4. ✅ Todos los checks de CI deben pasar
5. ✅ Los comentarios en el PR deben resolverse
6. ✅ El historial debe ser lineal (no merge commits)

## Flujo de Trabajo

Con estas protecciones, el flujo será:

```bash
# 1. Crear rama para feature
git checkout -b feature/nueva-funcionalidad

# 2. Hacer cambios y commits
git add .
git commit -m "Agregar nueva funcionalidad"

# 3. Push de la rama
git push origin feature/nueva-funcionalidad

# 4. Crear Pull Request en GitHub
# 5. Esperar a que pasen los checks de CI
# 6. Solicitar revisión de código
# 7. Una vez aprobado, hacer merge
```

## Configuración Adicional: CODEOWNERS

Para requerir revisión de personas específicas, crea un archivo `.github/CODEOWNERS`:

```
# CODEOWNERS
# Estas personas serán automáticamente solicitadas para revisión

# Todo el código
* @hectronix2005

# Configuración y deployment
/config/deploy.yml @hectronix2005
/.github/workflows/* @hectronix2005

# Base de datos
/db/migrate/* @hectronix2005

# Modelos críticos
/app/models/user.rb @hectronix2005
/app/models/vacation_request.rb @hectronix2005
```

## Verificar Configuración

Intenta hacer push directo a main:

```bash
git push origin main
```

Deberías recibir un error como:

```
remote: error: GH006: Protected branch update failed for refs/heads/main.
remote: error: Changes must be made through a pull request.
```

Esto confirma que la protección está funcionando correctamente.

## Excepciones de Emergencia

Si necesitas hacer un cambio urgente:

1. Temporalmente deshabilita la protección en Settings > Branches
2. Haz el push directo
3. Re-habilita la protección inmediatamente
4. Documenta la razón en un issue

## Recursos

- [GitHub Branch Protection Documentation](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/managing-protected-branches/about-protected-branches)
- [GitHub CODEOWNERS](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/about-code-owners)
