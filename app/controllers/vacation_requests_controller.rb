class VacationRequestsController < ApplicationController
  include UserManagement

  before_action :set_vacation_request, only: [ :show, :edit, :update, :destroy, :approve, :reject, :mark_as_taken, :export_pdf ]
  before_action :require_leader_or_hr_access, only: [ :pending, :approve, :reject ]
  before_action :require_hr_access, only: [ :mark_as_taken ]

  def index
    # Usar scope relevante según permisos del usuario
    @vacation_requests = vacation_requests_scope
    @vacation_requests = apply_request_filters(@vacation_requests)

    @pagy, @vacation_requests = pagy(@vacation_requests.includes(:user, :approved_by)
                                                       .order(created_at: :desc))
    @stats = user_dashboard_stats
    @filter_users = filter_users_for_current_user
    @areas = Area.ordered
  end

  def show
    permission_checker = UserPermissionChecker.new(current_user, @vacation_request.user)
    unless permission_checker.can_view?
      flash[:alert] = "No tienes permisos para ver esta solicitud"
      redirect_to vacation_requests_path
      return
    end
  end

  def new
    # Permitir crear solicitud para otro usuario si es HR
    @target_user = find_target_user_for_request
    @vacation_request = @target_user.vacation_requests.build
    @current_balance = @target_user.current_year_balance

    validate_vacation_balance_exists
  end

  def create
    @target_user = find_target_user_for_request
    @vacation_request = @target_user.vacation_requests.build(vacation_request_params)
    @current_balance = @target_user.current_year_balance

    if @vacation_request.save
      flash[:notice] = "Solicitud de #{@target_user.vacation_term} creada exitosamente"
      redirect_to @vacation_request
    else
      flash[:alert] = "Error al crear la solicitud" + @vacation_request.errors.full_messages.join(", ")
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @current_balance = @vacation_request.user.current_year_balance
  end

  def update
    @current_balance = @vacation_request.user.current_year_balance

    if @vacation_request.update(vacation_request_params)
      flash[:notice] = "Solicitud actualizada exitosamente"
      redirect_to @vacation_request
    else
      flash[:alert] = "Error al actualizar la solicitud" + @vacation_request.errors.full_messages.join(", ")
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    permission_checker = UserPermissionChecker.new(current_user, @vacation_request.user)
    unless permission_checker.can_manage? && @vacation_request.pending?
      flash[:alert] = "No puedes cancelar esta solicitud"
      redirect_to vacation_requests_path
      return
    end

    user_name = @vacation_request.user.name
    @vacation_request.destroy
    flash[:notice] = "Solicitud de #{user_name} cancelada exitosamente"
    redirect_to vacation_requests_path
  end

  def pending
    # Mostrar solicitudes pendientes según el rol
    @pending_requests = pending_requests_for_current_user
    @pagy, @pending_requests = pagy(@pending_requests.includes(:user, :vacation_approvals)
                                                    .order(created_at: :asc))
    @stats = user_dashboard_stats
  end

  def history
    @vacation_requests = current_user.vacation_requests
    @vacation_requests = @vacation_requests.send(params[:filter]) if params[:filter].present?
    @vacation_requests = @vacation_requests.includes(:user)
                                    .order(created_at: params[:sort] || "desc")
    @pagy, @vacation_requests = pagy(@vacation_requests)
    @history_requests = @vacation_requests
    @yearly_summary = yearly_vacation_summary
  end

  def calendar
    # Solo HR, administradores y líderes pueden ver el calendario
    unless current_user.hr? || current_user.admin? || current_user.leader?
      flash[:alert] = "No tienes permisos para acceder al calendario"
      redirect_to vacation_requests_path
      return
    end

    @year = params[:year]&.to_i || Date.current.year
    @month = params[:month]&.to_i || Date.current.month

    # Obtener vacaciones filtradas según el rol del usuario
    start_date = Date.new(@year, @month, 1)
    end_date = start_date.end_of_month

    @vacation_requests = calendar_vacation_scope
                         .includes(:user)
                         .where(status: [:approved, :taken])
                         .where(
                           "(start_date <= ? AND end_date >= ?) OR (start_date >= ? AND start_date <= ?)",
                           end_date, start_date, start_date, end_date
                         )
                         .order(:start_date)

    # Organizar vacaciones por día para mostrar en el calendario
    @vacation_days = {}
    @vacation_requests.each do |request|
      (request.start_date..request.end_date).each do |date|
        next unless date.month == @month && date.year == @year
        @vacation_days[date] ||= []
        @vacation_days[date] << request
      end
    end

    # Datos para navegación de calendario
    @prev_month = @month == 1 ? 12 : @month - 1
    @prev_year = @month == 1 ? @year - 1 : @year
    @next_month = @month == 12 ? 1 : @month + 1
    @next_year = @month == 12 ? @year + 1 : @year

    # Estadísticas del mes
    @stats = {
      total_requests: @vacation_requests.count,
      employees_on_vacation: @vacation_requests.map(&:user).uniq.count,
      days_requested: @vacation_requests.sum(&:days_requested)
    }
  end

  def import
    # Solo HR puede importar datos históricos
    unless current_user.hr? || current_user.admin?
      flash[:alert] = "No tienes permisos para importar datos"
      redirect_to vacation_requests_path
      return
    end

    if request.post?
      return process_import
    end
  end

  # Descargar archivo temporal de resultados de importación
  def download_import_result
    filename = params[:file]

    unless filename.present?
      flash[:alert] = "Archivo no especificado"
      redirect_to vacation_requests_path
      return
    end

    result_info = ImportResultService.get_result_file(current_user.id, filename)

    unless result_info
      flash[:alert] = "El archivo ha expirado o no existe"
      redirect_to vacation_requests_path
      return
    end

    send_file result_info[:filepath],
              filename: "reporte_importacion_vacaciones_#{Time.current.strftime('%Y%m%d_%H%M%S')}.txt",
              type: "text/plain",
              disposition: "attachment"
  end

  def country_working_days
    # API endpoint to provide current user's country working days configuration
    country = current_user.country

    # Obtener festivos del año actual y siguiente (para solicitudes que crucen años)
    current_year = Date.current.year
    holidays = []

    if country.g_country.present?
      year_holidays = Holidays.between(Date.current.beginning_of_year, Date.current.end_of_year + 1.year, country.g_country.to_sym)
      year_holidays.each do |holiday|
        holidays << holiday[:date].strftime('%Y-%m-%d')
      end
    end

    respond_to do |format|
      format.json do
        render json: {
          working_days: current_user.effective_working_days,
          holidays: holidays
        }
      end
    end
  end

  # Exportar solicitud individual como PDF
  def export_pdf
    permission_checker = UserPermissionChecker.new(current_user, @vacation_request.user)
    unless permission_checker.can_view?
      flash[:alert] = "No tienes permisos para exportar esta solicitud"
      redirect_to vacation_requests_path
      return
    end

    pdf_generator = VacationRequestPdfGenerator.new(@vacation_request)

    respond_to do |format|
      format.pdf do
        send_data pdf_generator.generate.render,
                  filename: pdf_generator.filename,
                  type: "application/pdf",
                  disposition: "attachment"
      end
    end
  end

  # Exportar múltiples solicitudes como ZIP
  def export_bulk
    # Aplicar los mismos filtros que en el index
    vacation_requests = vacation_requests_scope
    vacation_requests = apply_request_filters(vacation_requests)

    # Incluir relaciones necesarias para la generación de PDFs
    vacation_requests = vacation_requests.includes(:user, :approved_by)

    # Verificar que hay solicitudes para exportar
    if vacation_requests.empty?
      flash[:alert] = "No hay solicitudes para exportar con los filtros aplicados"
      redirect_to vacation_requests_path
      return
    end

    # Limitar la cantidad máxima de solicitudes para evitar problemas de memoria
    if vacation_requests.count > 100
      flash[:alert] = "Demasiadas solicitudes para exportar (máximo 100). Por favor, refina tus filtros."
      redirect_to vacation_requests_path
      return
    end

    zip_data = VacationRequestZipExporter.generate_for_requests(vacation_requests)

    respond_to do |format|
      format.zip do
        send_data zip_data[:content],
                  filename: zip_data[:filename],
                  type: zip_data[:content_type],
                  disposition: "attachment"
      end
    end
  end

  def approve
    permission_checker = UserPermissionChecker.new(current_user, @vacation_request.user)
    unless permission_checker.can_approve_vacation_for?
      flash[:alert] = "No tienes permisos para aprobar esta solicitud"
      redirect_to pending_vacation_requests_path
      return
    end

    approval_service = VacationApprovalService.new(@vacation_request, current_user)
    success, mssg = approval_service.approve!
    if success
      flash[:notice] = "Solicitud aprobada exitosamente "
      redirect_to pending_vacation_requests_path
    else
      flash[:alert] = "Error al aprobar la solicitud " + mssg
      redirect_to @vacation_request
    end
  end

  def reject
    permission_checker = UserPermissionChecker.new(current_user, @vacation_request.user)
    unless permission_checker.can_approve_vacation_for?
      flash[:alert] = "No tienes permisos para rechazar esta solicitud"
      redirect_to pending_vacation_requests_path
      return
    end

    @vacation_request.update!(
      status: :rejected,
      rejected_reason: params[:rejection_reason] || "Sin razón especificada"
    )

    redirect_to pending_vacation_requests_path
    flash[:notice] = "Solicitud rechazada"
  end

  def mark_as_taken
    if @vacation_request.approved?
      # Actualizar balance del usuario
      update_user_vacation_balance(@vacation_request)
      @vacation_request.update!(status: :taken)
      flash[:notice] = "Vacaciones marcadas como tomadas"
      redirect_to @vacation_request
    else
      flash[:alert] = "Solo se pueden marcar como tomadas las vacaciones aprobadas"
      redirect_to @vacation_request
    end
  end

  private

  def process_import
    unless params[:import_file].present?
      flash[:alert] = "Por favor selecciona un archivo para importar"
      redirect_to import_vacation_requests_path
      return
    end

    file = params[:import_file]
    unless file.content_type.in?(["text/csv"])
      flash[:alert] = "Por favor sube un archivo CSV o Excel"
      redirect_to import_vacation_requests_path
      return
    end

    begin
      import_results = import_historical_vacations(file)

      # Generar archivo temporal con resultados
      filename = ImportResultService.create_result_file(current_user.id, "vacaciones", import_results)

      if import_results[:success]
        flash[:notice] = "Importación exitosa: #{import_results[:imported]} registros importados.
                         <a href='#{download_import_result_vacation_requests_path}?file=#{filename}'
                            class='underline text-blue-600 hover:text-blue-800'>
                            Descargar reporte completo
                         </a>".html_safe
      else
        flash[:alert] = "Importación completada con errores.
                        <a href='#{download_import_result_vacation_requests_path}?file=#{filename}'
                           class='underline text-blue-600 hover:text-blue-800'>
                           Descargar reporte de errores
                        </a>".html_safe
      end

      redirect_to import_vacation_requests_path
    rescue => e
      Rails.logger.error "Error importing historical vacations: #{e.message}"
      flash[:alert] = "Error procesando el archivo: #{e.message}"
      redirect_to import_vacation_requests_path
    end
  end

  def import_historical_vacations(file)
    require "csv"

    imported = 0
    errors = []

    # Read the file content and handle BOM
    content = File.read(file.path, encoding: "ISO-8859-1").encode("UTF-8")
    content = content.gsub(/\A\uFEFF/, "")

    csv = CSV.parse(content, headers: true)
    csv.headers.map! { |header| header&.strip&.gsub(/\A[\uFEFF\u200B-\u200D\uFFFE\uFFFF]/, "") }

    csv.each_with_index do |row, idx|
      begin
        # Buscar usuario por documento o nombre
        user = find_user_for_import(row)
        unless user
          errors << "Usuario no encontrado: #{row['documento'] || row['nombre']}"
          next
        end

        if row["fecha_inicio"].blank? || row["fecha_fin"].blank?
          next
        end

        # Validar y crear solicitud de vacaciones histórica
        vacation_request = user.vacation_requests.build(
          start_date: Date.parse(row["fecha_inicio"]),
          end_date: Date.parse(row["fecha_fin"]),
          status: row["status"].present? ? row["status"] : :taken, # Marcar como tomadas (históricas)
          approved_by: current_user,
          approved_at: Date.parse(row["fecha_inicio"]) - 1.day,
          created_at: Date.parse(row["fecha_inicio"]) - 1.day,
          updated_at: Time.current,
          company: row["empresa"],
        )

        if vacation_request.save
          # Actualizar balance de vacaciones si es necesario
          update_user_vacation_balance(vacation_request)
          imported += 1
        else
          errors << "Fila #{idx+2}: #{vacation_request.errors.full_messages.join(', ')}"
        end
      rescue => e
        errors << "Fila #{idx+2}: #{e.message}"
      end
    end

    { success: errors.empty?, imported: imported, errors: errors }
  end

  def find_user_for_import(row)
    # Intentar encontrar por documento primero
    if row["documento"].present?
      user = User.where(document_number: row["documento"]).first_or_initialize

      if user.new_record?
        user.assign_attributes(
          document_number: row["documento"],
          email: row["correo"],
          name: row["nombre"],
          hire_date: row["fecha_ingreso"],
          country: Country.where(name: row["pais"]).first || Country.first,
          area: Area.where(name: row["area"]).first_or_create! || Area.first,
          employee: true,
          password: "123456",
          password_confirmation: "123456",
          active: true,
          company: row["empresa"],
        )
        user.employee = true if row["rol"] == "employee" || row["rol"] == "leader"
        user.leader = true if row["rol"] == "leader"
        user.hr = true if row["rol"] == "hr"
        user.employee = true if !user.leader? || !user.hr? || !user.employee?
        user.save!
      end
      user.company = row["empresa"]
      user.save! if user.changed_attributes.any?
      return user
    end
    nil
  end

  def calendar_vacation_scope
    if current_user.hr? || current_user.admin?
      # HR y administradores ven todas las vacaciones
      VacationRequest.all
    elsif current_user.leader?
      # Líderes solo ven las vacaciones de su equipo (incluyendo las suyas)
      user_ids = [current_user.id] + current_user.subordinates.pluck(:id)
      VacationRequest.where(user_id: user_ids)
    else
      # Otros usuarios no deberían acceder a esta función, pero por seguridad
      current_user.vacation_requests
    end
  end

  def set_vacation_request
    @vacation_request = VacationRequest.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "Solicitud no encontrada"
    redirect_to vacation_requests_path
  end

  def vacation_request_params
    params.require(:vacation_request).permit(:start_date, :end_date, :user_id, :status)
  end

  def find_target_user_for_request
    # Solo HR puede crear solicitudes para otros usuarios
    if params[:user_id].present? && current_user.hr?
      User.find(params[:user_id])
    else
      current_user
    end
  end

  def vacation_requests_scope
    if current_user.hr? || current_user.admin?
      VacationRequest.all
    elsif current_user.leader?
      # Líderes ven sus propias solicitudes y las de su equipo
      user_ids = [ current_user.id ] + current_user.subordinates.pluck(:id)
      VacationRequest.where(user_id: user_ids)
    else
      current_user.vacation_requests
    end
  end

  def apply_request_filters(scope)
    scope = scope.pending if params[:pending].present?
    scope = scope.where(status: params[:status]) if params[:status].present?
    scope = scope.where(user_id: params[:user_ids].select(&:present?)) if params[:user_ids]&.any?
    scope = scope.where("start_date >= ?", params[:start_date]) if params[:start_date].present?
    scope = scope.where("end_date <= ?", params[:end_date]) if params[:end_date].present?
    if params[:area_id].present?
      user_area_ids = User.where(area_id: params[:area_id]).pluck(:id)
      scope = scope.where("user_id in (?)", user_area_ids)
    end
    scope
  end

  def pending_requests_for_current_user
    if current_user.hr? || current_user.admin?
      VacationRequest.pending
    elsif current_user.leader?
      # Solicitudes del equipo que necesitan aprobación del líder
      VacationRequest.joins(:user)
                    .where(users: { lead_id: current_user.id })
                    .pending
    else
      VacationRequest.none
    end
  end

  def filter_users_for_current_user
    if current_user.hr? || current_user.admin?
      User.active.order(:name)
    elsif current_user.leader?
      User.where(id: [ current_user.id ] + current_user.subordinates.pluck(:id)).order(:name)
    else
      [ current_user ]
    end
  end

  def validate_vacation_balance_exists
    mssg = "#{@target_user.name} no tiene días de #{@target_user.vacation_term} asignados para este año. "
    mssg += "Contacta a Recursos Humanos."
    unless @current_balance
      flash[:alert] = mssg
      return redirect_to root_path
    end
  end

  def yearly_vacation_summary
    return {} unless current_user.current_year_balance

    balance = current_user.current_year_balance
    current_year = Date.current.year

    {
      days_available: balance.days_available,
      used_days: balance.used_days,
      requests_count: current_user.vacation_requests.count,
      approved_count: current_user.vacation_requests.approved.count
    }
  end

  def update_user_vacation_balance(vacation_request)
    balance = vacation_request.user.current_year_balance
    return unless balance

    new_used_days = balance.used_days + vacation_request.days_requested
    balance.update!(used_days: new_used_days)
  end
end
