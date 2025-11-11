class NavigationBuilder
  include ActionView::Helpers
  include Rails.application.routes.url_helpers
  def initialize(user)
    @user = user
  end

  def build_navigation
    base_items = common_navigation_items
    role_specific_items = role_specific_navigation

    {
      main: base_items,
      role_specific: role_specific_items,
      user_menu: user_menu_items
    }
  end

  private

  def common_navigation_items
    [
      {
        name: 'Dashboard',
        path: root_path,
        icon: 'home',
        active_controllers: ['dashboard']
      },
      {
        name: "Mis #{@user.vacation_term.capitalize}",
        path: vacation_requests_path,
        icon: 'calendar',
        active_controllers: ['vacation_requests']
      }
    ]
  end

  def role_specific_navigation

    if @user.hr? || @user.admin?
      hr_navigation_items
    elsif @user.leader?
      leader_navigation_items
    else
      employee_navigation_items
    end
  end

  def hr_navigation_items
    [
      {
        name: 'Gestión de Usuarios',
        path: users_path,
        icon: 'users',
        active_controllers: ['users'],
        badge: users_needing_attention_count
      },
      {
        name: 'Todas las Solicitudes',
        path: pending_vacation_requests_path,
        icon: 'clipboard-list',
        active_controllers: ['vacation_requests'],
        actions: ['pending'],
        badge: VacationRequest.pending.count
      },
      {
        name: 'Calendario de Vacaciones',
        path: calendar_vacation_requests_path,
        icon: 'calendar-days',
        active_controllers: ['vacation_requests'],
        actions: ['calendar']
      },
      {
        name: 'Importar Vacaciones',
        path: import_vacation_requests_path,
        icon: 'upload',
        active_controllers: ['vacation_requests'],
        actions: ['import']
      },
      {
        name: 'Balances de vacaciones',
        path: vacation_balances_path,
        icon: 'chart-bar',
        active_controllers: ['reports']
      }
    ]
  end

  def leader_navigation_items
    [
      {
        name: 'Mi Equipo',
        path: users_path,
        icon: 'user-group',
        active_controllers: ['users'],
        badge: @user.subordinates.active.count
      },
      {
        name: 'Solicitudes del Equipo',
        path: pending_vacation_requests_path,
        icon: 'clipboard-check',
        active_controllers: ['vacation_requests'],
        actions: ['pending'],
        badge: team_pending_requests_count
      },
      {
        name: 'Calendario del Equipo',
        path: calendar_vacation_requests_path,
        icon: 'calendar-days',
        active_controllers: ['vacation_requests'],
        actions: ['calendar']
      }
    ]
  end

  def employee_navigation_items
    [
      {
        name: 'Mi Historial',
        path: history_vacation_requests_path,
        icon: 'clock',
        active_controllers: ['vacation_requests'],
        actions: ['history']
      }
    ]
  end

  def user_menu_items
    items = [
      {
        name: 'Mi Perfil',
        path: user_path(@user.id),
        icon: 'user'
      },
      {
        name: 'Cambiar Contraseña',
        path: edit_user_path(@user),
        icon: 'key'
      }
    ]

    items << {
      name: 'Cerrar Sesión',
      path: logout_sessions_path,
      icon: 'logout',
      method: 'delete'
    }

    items
  end

  def users_needing_attention_count
    User.active.select(&:needs_vacation_alert?).count
  end

  def team_pending_requests_count
    return 0 unless @user.leader?

    @user.subordinates.joins(:vacation_requests)
         .where(vacation_requests: { status: 'pending' })
         .count
  end
end

