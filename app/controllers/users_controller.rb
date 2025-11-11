class UsersController < ApplicationController
  before_action :set_user, only: [ :show, :edit, :update, :destroy, :activate, :deactivate ]
  before_action :require_hr_access, only: [ :new, :create, :edit, :update, :destroy, :activate, :deactivate ]

  def index
    @users = if current_user.leader? && !current_user.hr? && !current_user.admin?
               current_user.subordinates.active.includes(:country, :lead).order(:name)
             else
               User.includes(:country, :lead).order(:name)
             end

    # Apply filters
    @users = @users.by_country(params[:country]) if params[:country].present?
    @users = @users.send(params[:role]) if params[:role].present?
    @users = @users.where(active: params[:active] == "true") if params[:active].present?
    @users = @users.with_high_vacation_balance if params[:alert].present?
    @users = @users.where(area_id: params[:area_id]) if params[:area_id].present?
    search = params[:user_search]
    @users = @users.where(
      "name ILIKE ? OR email ILIKE ? OR document_number ILIKE ?",
      "%#{search}%", "%#{search}%", "%#{search}%"
    ) if search.present?

    @pagy, @users = pagy(@users)
    @countries = Country.all
    @areas = Area.ordered
  end

  def show
    @vacation_balance = @user.current_year_balance
    @recent_requests = @user.vacation_requests.order(created_at: :desc).limit(10)
    @subordinates = @user.subordinates.active if @user.leader?
  end

  def new
    @user = User.new
    @countries = Country.all
    @leaders = User.leader.active.order(:name)
    @user.employee = true if @user.active_roles.empty?
    @areas = Area.ordered
  end

  def create
    @user = User.new(user_params)
    @user.active = true

    if @user.save
      flash[:notice] = "Usuario #{@user.name} creado exitosamente"
      redirect_to @user
    else
      @countries = Country.all
      @leaders = User.leader.active.order(:name)
      flash[:alert] = "Error al crear la solicitud" + @user.errors.full_messages.join(", ")
      @areas = Area.ordered
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @countries = Country.all
    #@leaders = User.leader.active.where.not(id: @user.id).order(:name)
    @leaders = User.leader.active.order(:name)
    @areas = Area.ordered
  end

  def update
    # Handle password update separately to allow optional password changes
    update_params = user_params
    if update_params[:password].blank? && update_params[:password_confirmation].blank?
      update_params = update_params.except(:password, :password_confirmation)
    end

    if @user.update(update_params)
      flash[:notice] = "Usuario actualizado exitosamente"
      redirect_to edit_user_path(@user)
    else
      @countries = Country.all
      @leaders = User.leader.active.where.not(id: @user.id).order(:name)
      @areas = Area.ordered
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    # Check for dependencies before allowing deletion
    if @user.vacation_requests.exists?
      flash[:alert] = "No se puede eliminar un usuario con solicitudes de vacaciones"
      redirect_to @user
    elsif @user.subordinates.exists?
      flash[:alert] = "No se puede eliminar un líder con subordinados asignados. Reasigna el equipo primero."
      redirect_to @user
    elsif @user == current_user
      flash[:alert] = "No puedes eliminar tu propia cuenta."
      redirect_to @user
    else
      user_name = @user.name
      @user.destroy
      flash[:notice] = "Usuario #{user_name} desactivado exitosamente"
      redirect_to users_path
    end
  end

  def activate
    @user.update!(active: true)
    flash[:notice] = "Usuario #{@user.name} activado exitosamente"
    redirect_to @user
  end

  def deactivate
    if @user == current_user
      flash[:alert] = "No puedes desactivar tu propia cuenta"
      redirect_to @user
    else
      @user.update!(active: false)
      flash[:notice] = "Usuario #{@user.name} desactivado exitosamente. No podrá acceder al sistema."
      redirect_to @user
    end
  end

  # Importar o actualizar usuarios desde CSV
  def import
    unless current_user.hr? || current_user.admin?
      flash[:alert] = "No tienes permisos para importar usuarios"
      redirect_to users_path
      return
    end

    if request.post?
      return process_import_users
    end
  end

  # Descargar archivo temporal de resultados de importación
  def download_import_result
    filename = params[:file]

    unless filename.present?
      flash[:alert] = "Archivo no especificado"
      redirect_to users_path
      return
    end

    result_info = ImportResultService.get_result_file(current_user.id, filename)

    unless result_info
      flash[:alert] = "El archivo ha expirado o no existe"
      redirect_to users_path
      return
    end

    send_file result_info[:filepath],
              filename: "reporte_importacion_usuarios_#{Time.current.strftime('%Y%m%d_%H%M%S')}.txt",
              type: "text/plain",
              disposition: "attachment"
  end

  # Endpoint para búsqueda de usuarios con Tom Select
  def search
    query = params[:q]
    users = if current_user.leader? && !current_user.hr? && !current_user.admin?
              current_user.subordinates.active.order(:name)
            else
              User.active.order(:name)
            end

    if query.present?
      users = users.where(
        "name ILIKE ? OR email ILIKE ? OR document_number ILIKE ?",
        "%#{query}%", "%#{query}%", "%#{query}%"
      )
    end

    users = users.limit(20)

    render json: users.map { |user|
      {
        value: user.id,
        text: "#{user.name} - #{user.email} - #{user.document_number}",
      }
    }
  end


  private

  def require_hr_access
    unless current_user&.hr? || current_user&.admin? || @user == current_user
      redirect_to root_path, alert: "No tienes permisos para acceder a esta sección"
    end
  end

  def set_user
    @user = User.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "Usuario no encontrado"
    redirect_to users_path
  end

  def user_params
    params.require(:user).permit(
      :document_number, :name, :phone, :email, :area_id, :country_id, :lead_id, :hire_date, :password,
      :password_confirmation, :company, :position, :active, :hr, :admin, :leader, :employee, :admin, working_days: {}
    )
  end

  def process_import_users
    unless params[:import_file].present?
      flash[:alert] = "Por favor selecciona un archivo para importar"
      redirect_to import_users_path
      return
    end

    file = params[:import_file]
    unless file.content_type.in?(["text/csv"])
      flash[:alert] = "Por favor sube un archivo CSV"
      redirect_to import_users_path
      return
    end

    require "csv"
    imported = 0
    updated = 0
    errors = []

    content = File.read(file.path, encoding: "ISO-8859-1").encode("UTF-8")
    content = content.gsub(/\A\uFEFF/, "")
    csv = CSV.parse(content, headers: true)
    csv.headers.map! { |header| header&.strip&.gsub(/\A[\uFEFF\u200B-\u200D\uFFFE\uFFFF]/, "") }

    csv.each_with_index do |row, idx|
      begin
        result = find_or_update_user_from_row(row)
        if result == :imported
          imported += 1
        elsif result == :updated
          updated += 1
        else
          errors << "Fila #{idx+2}: #{result}"
        end
      rescue => e
        errors << "Fila #{idx+2}: #{e.message}"
      end
    end

    # Generar archivo temporal con resultados
    results = {
      success: errors.empty?,
      imported: imported,
      updated: updated,
      errors: errors
    }

    filename = ImportResultService.create_result_file(current_user.id, "usuarios", results)

    if errors.empty?
      flash[:notice] = "Importación exitosa: #{imported} usuarios creados, #{updated} actualizados.
                       <a href='#{download_import_result_users_path}?file=#{filename}'
                          class='underline text-blue-600 hover:text-blue-800'>
                          Descargar reporte completo
                       </a>".html_safe
    else
      flash[:alert] = "Importación completada con errores.
                      <a href='#{download_import_result_users_path}?file=#{filename}'
                         class='underline text-blue-600 hover:text-blue-800'>
                         Descargar reporte de errores
                      </a>".html_safe
    end

    redirect_to import_users_path
  end

  def find_or_update_user_from_row(row)
    # Buscar por documento o correo
    user = nil
    if row["documento"].present?
      user = User.where(document_number: row["documento"]).first
    end
    if user.nil? && row["correo"].present?
      user = User.where(email: row["correo"]).first
    end
    is_new = false
    if user.nil?
      user = User.new
      is_new = true
    end
    user.assign_attributes(
      document_number: row["documento"],
      email: row["correo"],
      name: row["nombre"],
      hire_date: row["fecha_ingreso"],
      country: Country.where(name: row["pais"]).first || Country.first,
      area: Area.where(name: row["area"]).first_or_create! || Area.first,
      employee: true,
      active: true,
      company: row["empresa"],
      position: row["cargo"],
    )
    user.password = "123456" if is_new
    user.password_confirmation = "123456" if is_new
    user.employee = true if row["rol"] == "employee" || row["rol"] == "leader"
    user.leader = true if row["rol"] == "leader"
    user.hr = true if row["rol"] == "hr"
    if row["dias_trabajados"].present?
      working_days_hash = {}
      # Inicializar todos los días como false
      %w[monday tuesday wednesday thursday friday saturday sunday].each do |day|
        working_days_hash[day] = false
      end

      # Establecer como true los días especificados en el CSV
      row["dias_trabajados"].split(",").map(&:strip).each do |day|
        # Normalizar el día al formato esperado (inglés, minúsculas)
        normalized_day = normalize_day_name(day.downcase)
        working_days_hash[normalized_day] = true if normalized_day
      end

      user.working_days = working_days_hash
    end
    user.employee = true if !user.leader? || !user.hr? || !user.employee?
    user.lead = User.where(document_number: row["lider_documento"]).first if row["lider_documento"].present?
    if user.save
      return is_new ? :imported : :updated
    else
      return user.errors.full_messages.join(", ")
    end
  end

  def normalize_day_name(day)
    day_mappings = {
      # Inglés completo
      "monday" => "monday", "tuesday" => "tuesday", "wednesday" => "wednesday",
      "thursday" => "thursday", "friday" => "friday", "saturday" => "saturday", "sunday" => "sunday",
      # Inglés abreviado
      "mon" => "monday", "tue" => "tuesday", "wed" => "wednesday",
      "thu" => "thursday", "fri" => "friday", "sat" => "saturday", "sun" => "sunday",
      # Español
      "lunes" => "monday", "martes" => "tuesday", "miércoles" => "wednesday", "miercoles" => "wednesday",
      "jueves" => "thursday", "viernes" => "friday", "sábado" => "saturday", "sabado" => "saturday", "domingo" => "sunday"
    }

    day_mappings[day]
  end
end
