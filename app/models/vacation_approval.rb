class VacationApproval < ApplicationRecord
  belongs_to :vacation_request
  belongs_to :user

  enum :status, {
    pending: 0,
    approved: 1,
    rejected: 2
  }, default: :pending

  validates :role, presence: true
  validates :approved_at, presence: true, if: -> { approved? || rejected? }
  validates :vacation_request_id, uniqueness: { scope: :role,
                                               message: "ya tiene una aprobación para este rol" }
  validate :user_can_approve_for_role
  validate :role_is_configured

  before_validation :set_role_from_user, if: -> { role.blank? }

  # Scope para obtener aprobaciones por rol
  scope :by_role, ->(role) { where(role: role) }
  scope :for_config, ->(config) { where(role: config.role) }

  def set_role_from_user
    return if role.present?

    # Determinar el rol basado en los permisos del usuario y la configuración
    user_roles = user.active_roles
    active_config_roles = VacationApprovalConfig.roles_that_can_approve

    # Encontrar el primer rol que coincida con la configuración activa
    matching_role = (user_roles & active_config_roles).first
    self.role = matching_role if matching_role
  end

  # Instance methods
  def approver_name
    user.full_name
  end

  def role_display_name
    I18n.t("users.roles.#{role}", default: role.to_s.humanize)
  end

  def approval_config
    @approval_config ||= VacationApprovalConfig.find_by(role: role)
  end

  def required_approval?
    approval_config&.required? || false
  end

  private

  def user_can_approve_for_role
    return unless user && role.present?

    # Verificar que el usuario tenga el rol requerido
    unless user.active_roles.include?(role.to_sym)
      errors.add(:user, "No tienes el rol #{role_display_name} para aprobar solicitudes")
      return
    end

    # Verificar que el rol esté configurado como activo
    config = VacationApprovalConfig.find_by(role: role.to_sym)
    unless config&.active?
      errors.add(:role, "El rol #{role_display_name} no está activo para aprobaciones")
    end
  end

  def role_is_configured
    return unless role.present?

    unless VacationApprovalConfig.roles_that_can_approve.include?(role.to_sym)
      errors.add(:role, "El rol #{role} no está configurado para aprobaciones")
    end
  end
end
