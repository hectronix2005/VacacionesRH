class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Include Pagy helpers for pagination
  include Pagy::Backend
  include UserManagement

  # Authentication and authorization
  before_action :require_authentication, :set_locale

  helper_method :current_user, :user_signed_in?, :current_user_can_manage?, :current_user_can_view?

  protected

  # Authentication helpers
  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  rescue ActiveRecord::RecordNotFound
    session[:user_id] = nil
    nil
  end

  def user_signed_in?
    current_user.present?
  end

  def require_authentication
    unless user_signed_in?
      store_location
      redirect_to login_sessions_path, alert: "Debes iniciar sesión para continuar"
    end
  end

  def require_no_authentication
    if user_signed_in?
      redirect_to root_path, notice: "Ya has iniciado sesión"
    end
  end

  # Authorization helpers
  def require_hr_access
    unless current_user&.hr? || current_user&.admin?
      redirect_to root_path, alert: "No tienes permisos para acceder a esta sección"
    end
  end

  def require_leader_or_hr_access
    unless current_user&.can_approve_requests?
      redirect_to root_path, alert: "No tienes permisos para acceder a esta sección"
    end
  end

  # Session management
  def sign_in(user)
    session[:user_id] = user.id
    @current_user = user
  end

  def sign_out
    session[:user_id] = nil
    @current_user = nil
  end

  def set_locale
    I18n.locale = params[:locale] || :es
  end

  private

  def store_location
    session[:return_to] = request.fullpath if request.get?
  end

  def redirect_back_or(default_path)
    redirect_to session.delete(:return_to) || default_path
  end
end
