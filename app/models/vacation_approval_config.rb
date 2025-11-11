class VacationApprovalConfig < ApplicationRecord
  validates :role, presence: true, uniqueness: true
  validates :order_position, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :minimum_approvals, presence: true, numericality: { greater_than: 0 }

  scope :active, -> { where(active: true) }
  scope :required, -> { where(required: true) }
  scope :ordered, -> { order(:order_position) }

  # Roles disponibles en el sistema
  AVAILABLE_ROLES = %w[leader hr admin].freeze

  def self.approval_workflow
    active.required.ordered.pluck(:role, :minimum_approvals).to_h
  end

  def self.roles_that_can_approve
    active.pluck(:role).map(&:to_sym)
  end

  def self.setup_default_config!
    return if exists?

    configs = [
      { role: 'leader', required: true, order_position: 1, minimum_approvals: 1,
        description: 'Aprobación del líder directo' },
      { role: 'hr', required: true, order_position: 2, minimum_approvals: 1,
        description: 'Aprobación de Recursos Humanos' }
    ]

    configs.each { |config| create!(config) }
  end

  def role_display_name
    I18n.t("users.roles.#{role}", default: role.to_s.humanize)
  end

  def can_be_deleted?
    # No permitir eliminar si es el último rol activo requerido
    return false if required? && self.class.active.required.count == 1
    true
  end

  def destroy
    update(active: false)
  end
end
