class UserPermissionChecker
  def initialize(current_user, target_user)
    @current_user = current_user
    @target_user = target_user
  end

  def can_manage?
    return false unless @current_user && @target_user

    # HR puede gestionar a cualquier usuario
    return true if @current_user.hr? || @current_user.admin?

    # Líderes pueden gestionar a sus subordinados
    return true if @current_user.leader? && @target_user.leader == @current_user

    # Usuarios pueden gestionar acciones limitadas sobre sí mismos
    @current_user == @target_user
  end

  def can_view?
    return false unless @current_user && @target_user
    return true if @current_user.admin?

    # Los usuarios pueden verse a sí mismos
    return true if @current_user == @target_user

    # HR puede ver a todos
    return true if @current_user.hr?

    # Líderes pueden ver a sus subordinados
    @current_user.leader? && @target_user.lead == @current_user
  end

  def can_approve_vacation_for?
    return false unless @current_user && @target_user
    return true if @current_user.admin?
    return false if @current_user == @target_user # No puede aprobar sus propias vacaciones

    # HR puede aprobar para cualquiera
    return true if @current_user.hr?

    # Líderes pueden aprobar para sus subordinados
    @current_user.leader? && @target_user.lead == @current_user
  end

  def can_create_vacation_for?
    return false unless @current_user && @target_user

    # Solo HR puede crear solicitudes para otros usuarios
    return true if @current_user.hr? || @current_user.admin?

    # Los usuarios solo pueden crear para sí mismos
    @current_user == @target_user
  end
end

