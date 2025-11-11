class VacationRequest < ApplicationRecord
  # Relationships
  belongs_to :user
  belongs_to :approved_by, class_name: 'User', optional: true
  has_many :vacation_approvals, dependent: :destroy

  # Enums
  enum :status, {
    pending: 0,
    approved: 1,
    rejected: 2,
    taken: 3
  }, default: :pending

  # Validations
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :days_requested, presence: true,
                             numericality: { greater_than: 0 }
  validate :end_date_after_start_date
  validate :no_overlapping_approved_requests
  before_validation :calculate_vacation_days
  before_validation :add_company

  # Scopes para integración con la nueva arquitectura
  scope :by_status, ->(status) { where(status: status) }
  scope :for_user, ->(user) { where(user: user) }
  scope :for_year, ->(year) { where('EXTRACT(year FROM start_date) = ?', year) }
  scope :pending_approval, -> { where(status: :pending) }
  scope :approved_requests, -> { where(status: [:approved, :taken]) }
  scope :recent, -> { where('created_at >= ?', 30.days.ago) }
  scope :by_date_range, ->(start_date, end_date) { where(start_date: start_date..end_date) }

  def approved?
    super || taken?
  end

  def can_be_cancelled?
    pending? && start_date > Date.current
  end

  def vacation_term
    user.vacation_term
  end

  def days_until_start
    return 0 if start_date <= Date.current
    (start_date - Date.current).to_i
  end

  def is_current?
    Date.current.between?(start_date, end_date)
  end

  # Métodos para verificar estado de aprobación específico
  def pending_approvals_needed
    return [] unless pending?

    workflow = VacationApprovalConfig.approval_workflow
    needed_roles = []

    workflow.each do |role, min_approvals|
      current_approvals = vacation_approvals.by_role(role).approved.count
      needed_roles << role if current_approvals < min_approvals
    end

    needed_roles
  end

  def fully_approved?
    # Verificar que todas las aprobaciones requeridas estén completas
    workflow = VacationApprovalConfig.approval_workflow

    workflow.all? do |role, min_approvals|
      vacation_approvals.by_role(role).approved.count >= min_approvals
    end
  end

  def can_be_approved_by?(user)
    return false unless user
    return false unless pending?

    # Obtener roles del usuario que pueden aprobar según la configuración
    user_roles = user.active_roles
    active_config_roles = VacationApprovalConfig.roles_that_can_approve

    # El usuario debe tener al menos un rol que pueda aprobar según la configuración
    return false if (user_roles & active_config_roles).empty?

    # Verificar si el usuario puede aprobar basado en la configuración dinámica
    user_roles.each do |role|
      next unless active_config_roles.include?(role)

      config = VacationApprovalConfig.find_by(role: role, active: true)
      next unless config

      # Verificar si ya se alcanzó el mínimo de aprobaciones para este rol
      current_approvals = vacation_approvals.by_role(role).approved.count
      next if current_approvals >= config.minimum_approvals

      # Lógica específica por rol para determinar si puede aprobar
      case role
      when :admin, :hr
        # HR puede aprobar cualquier solicitud pendiente
        return true
      when :leader
        # Los líderes solo pueden aprobar solicitudes de sus subordinados
        return self.user.lead_id == user.id
      else
        # Para cualquier otro rol configurado, permitir aprobación
        return false
      end
    end

    false
  end

  def approval_progress_percentage
    return 100 if approved? || rejected?
    return 0 if vacation_approvals.empty?

    workflow = VacationApprovalConfig.approval_workflow
    return 100 if workflow.empty?

    total_required = workflow.values.sum
    current_approved = 0

    workflow.each do |role, min_approvals|
      approved_count = vacation_approvals.by_role(role).approved.count
      current_approved += [approved_count, min_approvals].min
    end

    (current_approved * 100.0 / total_required).round
  end

  def approvals_summary
    summary = {}

    VacationApprovalConfig.active.ordered.each do |config|
      approvals = vacation_approvals.by_role(config.role).approved
      required_count = config.minimum_approvals
      current_count = approvals.count

      summary[config.role] = {
        required: required_count,
        current: current_count,
        completed: current_count >= required_count,
        approvers: approvals.map { |a| { name: a.user.full_name, approved_at: a.approved_at } },
        config: config
      }
    end

    summary
  end

  def calculate_vacation_days
    return 0 unless start_date && end_date
    return 0 unless user&.country

    # Use country-specific business days calculation
    self.days_requested = user.business_days_between(
      start_date,
      end_date
    )
  end

  # Métodos de validación
  private

  def add_company
    self.company = user.company if company.blank? && user.company.present?
  end

  def end_date_after_start_date
    return unless start_date && end_date

    errors.add(:end_date, 'debe ser posterior a la fecha de inicio') if end_date < start_date
  end

  def no_overlapping_approved_requests
    return unless user && start_date && end_date && !taken?

    overlapping = user.vacation_requests
                      .approved_requests
                      .where.not(id: id)
                      .where(
                        '(start_date <= ? AND end_date >= ?) OR (start_date <= ? AND end_date >= ?) OR (start_date >= ? AND end_date <= ?)',
                        start_date, start_date,
                        end_date, end_date,
                        start_date, end_date
                      )

    if overlapping.exists?
      errors.add(:start_date, 'ya tienes vacaciones aprobadas en este período')
    end
  end
end
