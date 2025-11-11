# PicapRh - Documentación

Bienvenido a la documentación de **PicapRh**, el sistema integral de gestión de vacaciones diseñado para empresas en Colombia y México.

## Contenido

- [Instalación](installation.md)
- [Guía de Usuario](user-guide.md)
- [Arquitectura del Sistema](architecture.md)
- [API Documentation](api.md)
- [Deployment](deployment.md)

## Resumen del Sistema

PicapRh es una aplicación web construida con Ruby on Rails 8.0.4 que proporciona:

- **Gestión de Vacaciones**: Solicitudes, aprobaciones y seguimiento completo
- **Sistema Multinivel**: Aprobación secuencial por Líder y Recursos Humanos
- **Multi-país**: Soporte para Colombia (vacaciones) y México (días de descanso)
- **Control de Acceso**: Sistema robusto basado en roles
- **Reportes**: Generación de PDFs y exportación masiva

## Inicio Rápido

```bash
# Clonar el repositorio
git clone https://github.com/hectronix2005/VacacionesRH.git
cd VacacionesRH

# Instalar dependencias
bundle install

# Configurar base de datos
rails db:create db:migrate db:seed

# Iniciar servidor
bin/dev
```

Accede a http://localhost:3000 y usa las credenciales de prueba del [README](https://github.com/hectronix2005/VacacionesRH#readme).

## Stack Tecnológico

| Tecnología | Versión | Propósito |
|-----------|---------|-----------|
| Ruby | 3.4.5 | Lenguaje de programación |
| Rails | 8.0.4 | Framework web |
| PostgreSQL | latest | Base de datos producción |
| TailwindCSS | 4.1.16 | Framework CSS |
| Hotwire | latest | JavaScript framework |
| RSpec | latest | Testing framework |

## Arquitectura

PicapRh sigue el patrón MVC de Rails con los siguientes componentes clave:

- **Modelos**: User, VacationRequest, VacationBalance, VacationApproval
- **Controladores**: Dashboard, VacationRequests, Users, Sessions
- **Servicios**: VacationApprovalService, VacationBalanceCalculator
- **Jobs**: RecalculateBalancesJob, UpdateVacationRequestJob

## Contribución

Para contribuir al proyecto:

1. Fork el repositorio
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## Soporte

Para reportar problemas o solicitar características:
- [Issues en GitHub](https://github.com/hectronix2005/VacacionesRH/issues)

## Licencia

Proyecto de uso empresarial interno.
