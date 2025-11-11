class VacationApprovalConfigsController < ApplicationController
  before_action :require_admin_or_hr_access
  before_action :set_vacation_approval_config, only: [:show, :edit, :update, :destroy]

  def index
    @configs = VacationApprovalConfig.ordered
    @available_roles = VacationApprovalConfig::AVAILABLE_ROLES - @configs.pluck(:role)
  end

  def show
  end

  def new
    @config = VacationApprovalConfig.new
    @available_roles = VacationApprovalConfig::AVAILABLE_ROLES - VacationApprovalConfig.pluck(:role)

    if @available_roles.empty?
      flash[:alert] = "Todos los roles disponibles ya están configurados"
      redirect_to vacation_approval_configs_path
    end
  end

  def create
    @config = VacationApprovalConfig.new(config_params)

    if @config.save
      flash[:notice] = "Configuración de aprobación creada exitosamente"
      redirect_to vacation_approval_configs_path
    else
      @available_roles = VacationApprovalConfig::AVAILABLE_ROLES - VacationApprovalConfig.pluck(:role)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @available_roles = VacationApprovalConfig::AVAILABLE_ROLES
  end

  def update
    if @config.update(config_params)
      flash[:notice] = "Configuración actualizada exitosamente"
      redirect_to vacation_approval_configs_path
    else
      @available_roles = VacationApprovalConfig::AVAILABLE_ROLES
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    unless @config.can_be_deleted?
      flash[:alert] = "No se puede eliminar esta configuración"
      redirect_to vacation_approval_configs_path
      return
    end

    @config.destroy
    flash[:notice] = "Configuración eliminada exitosamente"
    redirect_to vacation_approval_configs_path
  end

  def setup_defaults
    VacationApprovalConfig.setup_default_config!
    flash[:notice] = "Configuración por defecto establecida"
    redirect_to vacation_approval_configs_path
  end

  private

  def set_vacation_approval_config
    @config = VacationApprovalConfig.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = "Configuración no encontrada"
    redirect_to vacation_approval_configs_path
  end

  def config_params
    params.require(:vacation_approval_config).permit(
      :role, :required, :order_position, :active, :description, :minimum_approvals
    )
  end

  def require_admin_or_hr_access
    unless current_user&.admin? || current_user&.hr?
      flash[:alert] = "No tienes permisos para acceder a esta sección"
      redirect_to root_path
    end
  end
end
