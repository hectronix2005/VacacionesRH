class AreasController < ApplicationController
  before_action :set_area, only: [:show, :edit, :update, :destroy]
  before_action :require_hr_or_admin_access

  def index
    @areas = Area.ordered.includes(:users)
    @pagy, @areas = pagy(@areas)
  end

  def show
    @users = @area.users.active.includes(:country, :lead).order(:name)
    @users_count = @area.users_count
    @active_users_count = @area.active_users_count
  end

  def new
    @area = Area.new
  end

  def create
    @area = Area.new(area_params)

    if @area.save
      flash[:notice] = "Área '#{@area.name}' creada exitosamente"
      redirect_to areas_path
    else
      flash.now[:alert] = "Error al crear el área: #{@area.errors.full_messages.join(', ')}"
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @area.update(area_params)
      flash[:notice] = "Área '#{@area.name}' actualizada exitosamente"
      redirect_to @area
    else
      flash.now[:alert] = "Error al actualizar el área: #{@area.errors.full_messages.join(', ')}"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
      @area.users.update_all(area_id: nil)
      area_name = @area.name
      @area.destroy
      flash[:notice] = "Área '#{area_name}' eliminada exitosamente"
      redirect_to areas_path
  end

  private

  def set_area
    @area = Area.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    flash[:alert] = 'Área no encontrada'
    redirect_to areas_path
  end

  def area_params
    params.require(:area).permit(:name)
  end

  def require_hr_or_admin_access
    unless current_user&.hr? || current_user&.admin?
      flash[:alert] = "No tienes permisos para gestionar las áreas"
      redirect_to dashboard_path
    end
  end
end
