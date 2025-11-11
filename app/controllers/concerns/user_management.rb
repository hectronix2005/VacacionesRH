module UserManagement
  extend ActiveSupport::Concern

  included do
    helper_method :current_user_can_manage?, :current_user_can_view?, :user_dashboard_stats
  end

  # Single Responsibility: Gestión de permisos de usuario
  def current_user_can_manage?(target_user)
    return false unless current_user && target_user

    # Aplicando Open/Closed Principle: Fácil de extender sin modificar
    permission_checker = UserPermissionChecker.new(current_user, target_user)
    permission_checker.can_manage?
  end

  def current_user_can_view?(target_user)
    return false unless current_user && target_user

    permission_checker = UserPermissionChecker.new(current_user, target_user)
    permission_checker.can_view?
  end

  # DRY: Stats compartidas entre diferentes vistas
  def user_dashboard_stats(user = current_user)
    @user_stats ||= UserStatsService.new(user).generate_stats
  end

  # Navegación contextual según permisos
  def navigation_items_for_user
    @navigation_items ||= NavigationBuilder.new(current_user).build_navigation
  end
end

