class VacationApprovalService
  def initialize(vacation_request, approver)
    @vacation_request = vacation_request
    @approver = approver
  end

  def approve!
    return false unless can_approve?

    # Crear o encontrar la aprobación para este usuario y rol
    approval = find_or_create_approval_for_user
    return false unless approval

    # Marcar como aprobada
    approval.update!(
      status: :approved,
      approved_at: Time.current,
      comments: "Aprobado por #{@approver.name}"
    )

    # Verificar si todas las aprobaciones están completas
    check_and_update_request_status

    true
  rescue => e
    Rails.logger.error "Error al aprobar solicitud: #{e.message}"
    Rails.logger.error "solicitud: #{approval.as_json}"
    Rails.logger.error "Error al aprobar solicitud: #{e.backtrace.join("\n")}"
    [false, e.message]
  end

  def reject!(reason = nil)
    return false unless can_approve?

    approval = find_or_create_approval_for_user
    return false unless approval

    approval.update!(
      status: :rejected,
      approved_at: Time.current,
      comments: reason || "Rechazado por #{@approver.name}"
    )

    # Si cualquier aprobación es rechazada, toda la solicitud se rechaza
    @vacation_request.update!(status: :rejected)

    true
  rescue => e
    Rails.logger.error "Error al rechazar solicitud: #{e.message}"
    Rails.logger.error "Error al rechazar solicitud: #{e.backtrace.join("\n")}"
    false
  end

  private

  def can_approve?
    @vacation_request.can_be_approved_by?(@approver)
  end

  def find_or_create_approval_for_user
    # Determinar el rol del aprobador basado en la configuración activa
    approver_roles = @approver.active_roles
    active_roles = VacationApprovalConfig.roles_that_can_approve

    # Encontrar el primer rol válido del usuario que pueda aprobar
    matching_role = (approver_roles & active_roles).first
    return nil unless matching_role

    # Buscar aprobación existente o crear una nueva
    @vacation_request.vacation_approvals.find_or_create_by(
      user: @approver,
      role: matching_role
    ) do |approval|
      approval.status = :pending
    end
  end

  def check_and_update_request_status
    # Si hay alguna aprobación rechazada, la solicitud se rechaza
    if @vacation_request.vacation_approvals.rejected.exists?
      @vacation_request.update!(status: :rejected)
      return
    end

    # Verificar si todas las aprobaciones requeridas están completas
    if @vacation_request.fully_approved?
      @vacation_request.update!(
        status: :approved,
        approved_by: @approver,
        approved_at: Time.current
      )
      user = @vacation_request.user
      VacationRequestMailer.with(name: user.name, email: user.email).approved.deliver_later if user.email.present?
    end
  end
end
