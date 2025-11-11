class SessionsController < ApplicationController
  skip_before_action :require_authentication, only: [ :new, :create ]
  before_action :require_no_authentication, only: [ :new, :create ]
  layout "sessions/application"
  def new
  end

  def create
    user = User.find_by(document_number: login_params[:document_number])

    if user&.authenticate(login_params[:password])
      if user.active?
        sign_in(user)
        redirect_back_or(root_path)
        flash[:notice] = "¡Bienvenido, #{user.full_name}!"
      else
        flash.now[:alert] = "Tu cuenta ha sido desactivada. Contacta a Recursos Humanos."
        render :new, status: :unprocessable_entity
      end
    else
      flash.now[:alert] = "Número de documento o contraseña incorrectos"
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    user_name = current_user&.full_name
    sign_out
    redirect_to login_sessions_path
    flash[:notice] = "¡Hasta luego, #{user_name}!"
  end

  private

  def login_params
    params.require(:session).permit(:document_number, :password)
  end
end
