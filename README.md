# PicapRh - Sistema de Gestión de Vacaciones

**PicapRh** es un sistema integral de gestión de vacaciones desarrollado en Ruby on Rails 8.0.2, diseñado específicamente para empresas colombianas y mexicanas. El sistema maneja flujos de trabajo de aprobación multinivel para solicitudes de vacaciones, soporta diferentes terminologías de vacaciones por país y proporciona control de acceso basado en roles.

## 🌟 Características Principales

### 🔄 Sistema de Aprobación Multinivel
- **Aprobación Dual**: Requiere aprobación tanto del líder como de Recursos Humanos
- **Flujo Dinámico**: Sistema extensible para agregar más roles y niveles de aprobación
- **Seguimiento de Progreso**: Visualización del estado de aprobación en tiempo real
- **Comentarios**: Cada aprobador puede agregar comentarios explicativos

### 🌍 Soporte Específico por País
- **Colombia**: Maneja "vacaciones" con 15 días anuales estándar
- **México**: Maneja "días de descanso" con 12 días anuales para contratos de servicios
- **Terminología Localizada**: Adapta automáticamente el lenguaje según el país

### 👥 Control de Acceso Basado en Roles
- **Empleados**: Pueden solicitar vacaciones, ver su historial y balance
- **Líderes**: Pueden aprobar solicitudes de su equipo y ver estadísticas del equipo
- **Recursos Humanos**: Control total del sistema, gestión de usuarios y reportes

### 📊 Dashboard Integral
- **Específico por Rol**: Cada rol ve información relevante a sus responsabilidades
- **Estadísticas en Tiempo Real**: Métricas de solicitudes, aprobaciones y balances
- **Acciones Rápidas**: Enlaces directos a las funciones más utilizadas

### 💰 Gestión de Balance de Vacaciones
- **Seguimiento Anual**: Control de días totales, usados y disponibles
- **Validación Automática**: Previene solicitudes que excedan el balance disponible
- **Historial Completo**: Registro detallado de todas las transacciones de días

### 📄 Sistema de Paginación Eficiente
- **Pagy v8.6.3**: Paginación eficiente para grandes conjuntos de datos
- **Localización en Español**: Interfaz completamente traducida
- **Responsive**: Navegación adaptada para móviles y escritorio

## 🛠 Tecnologías Utilizadas

- **Ruby on Rails 8.0.2**: Framework principal
- **SQLite3**: Base de datos (desarrollo/pruebas)
- **TailwindCSS v4**: Framework CSS para diseño responsive
- **Hotwire (Turbo + Stimulus)**: JavaScript moderno sin complejidad
- **BCrypt**: Autenticación segura con hash de contraseñas
- **Pagy**: Paginación eficiente
- **RSpec**: Suite de pruebas completa

## 🚀 Instalación y Configuración

### Prerrequisitos
- Ruby 3.x
- Rails 8.0.2
- Node.js (para asset pipeline)
- SQLite3

### Pasos de Instalación

1. **Clonar el repositorio**
   ```bash
   git clone [repository-url]
   cd picap_rh
   ```

2. **Instalar dependencias**
   ```bash
   bundle install
   ```

3. **Configurar la base de datos**
   ```bash
   rails db:create
   rails db:migrate
   rails db:seed
   ```

4. **Iniciar el servidor de desarrollo**
   ```bash
   bin/dev
   # O alternativamente:
   rails server
   ```

5. **Acceder al sistema**
   - Abrir navegador en `http://localhost:3000`
   - Usar las credenciales de prueba (ver sección de Credenciales)

## 👤 Roles y Capacidades

### 🟢 Empleado
- ✅ Ver balance de días de vacaciones
- ✅ Crear nuevas solicitudes de vacaciones
- ✅ Ver historial completo de solicitudes
- ✅ Cancelar solicitudes pendientes
- ✅ Seguir el progreso de aprobaciones

### 🟡 Líder
- ✅ Todas las capacidades de Empleado
- ✅ Ver solicitudes pendientes de su equipo
- ✅ Aprobar/rechazar solicitudes como primer nivel
- ✅ Ver estadísticas del equipo
- ✅ Acceso a dashboard de liderazgo

### 🔴 Recursos Humanos (HR)
- ✅ Todas las capacidades anteriores
- ✅ Ver todas las solicitudes del sistema
- ✅ Aprobación final de solicitudes
- ✅ Marcar vacaciones como tomadas
- ✅ Gestión completa de usuarios
- ✅ Reportes y estadísticas globales
- ✅ Identificar usuarios con días acumulados

## 🔑 Credenciales de Prueba

### Colombia
```
HR Colombia:
- Documento: 12345678
- Contraseña: password123

Líder Colombia:
- Documento: 87654321
- Contraseña: password123

Empleado Colombia:
- Documento: 11223344
- Contraseña: password123
```

### México
```
HR México:
- Documento: CURP123456
- Contraseña: password123

Líder México:
- Documento: CURP789012
- Contraseña: password123

Empleado México:
- Documento: CURP345678
- Contraseña: password123
```

## 🔄 Flujo de Trabajo de Aprobación

1. **Empleado** crea solicitud → Estado: `Pendiente`
2. **Líder** aprueba → Estado: `Pendiente HR`
3. **HR** aprueba → Estado: `Completamente Aprobada`
4. **HR** marca como tomada → Estado: `Tomada` + Actualización de balance

## 🎯 Características Técnicas

### Controladores Stimulus
- **DateCalculatorController**: Cálculo automático de días solicitados
- **ModalController**: Gestión de modales para rechazos
- **BulkActionsController**: Acciones masivas (preparado para futuras implementaciones)
- **TabSwitcherController**: Navegación por pestañas

### Modelos Principales
- **User**: Gestión de usuarios con roles y jerarquías
- **VacationRequest**: Solicitudes con estado y validaciones
- **VacationApproval**: Seguimiento de aprobaciones por rol
- **VacationBalance**: Control de días disponibles por año

### Características de Seguridad
- Autenticación BCrypt
- Autorización basada en roles
- Validación de permisos en cada acción
- Protección CSRF habilitada

## 🧪 Desarrollo y Pruebas

### Comandos Principales
```bash
# Ejecutar pruebas
bundle exec rspec

# Verificar estilo de código
bundle exec rubocop

# Escanear vulnerabilidades de seguridad
bundle exec brakeman

# Reiniciar base de datos
rails db:reset

# Consola de Rails
rails console

# Servidor de desarrollo con TailwindCSS
bin/dev
```

### Datos de Prueba
El sistema incluye un archivo de seeds completo que crea:
- 8 usuarios (HR, líderes y empleados)
- Balances de vacaciones para el año actual
- 6 solicitudes de ejemplo en diferentes estados
- 5 aprobaciones que demuestran el flujo multinivel

## 📱 Diseño Responsive

- **Mobile First**: Diseñado primero para móviles
- **TailwindCSS**: Utilidades responsive integradas
- **Componentes Adaptables**: Tablas, modales y navegación optimizada
- **Accesibilidad**: Cumple estándares de accesibilidad web

## 🔮 Extensibilidad Futura

El sistema está diseñado para ser fácilmente extensible:

- **Más Roles**: Agregar supervisor, finanzas, etc.
- **Más Niveles de Aprobación**: Sistema dinámico configurable
- **Nuevos Países**: Soporte para terminologías adicionales
- **Reportes Avanzados**: Framework preparado para análisis complejos

## 📄 Licencia

Este proyecto está desarrollado para uso empresarial interno.

---

## 🆘 Soporte

Para reportar problemas o solicitar características:
1. Revisar la documentación completa
2. Verificar los logs de desarrollo
3. Contactar al equipo de desarrollo

**¡El sistema está listo para gestionar las vacaciones de tu empresa de manera eficiente y profesional!** 🎉
