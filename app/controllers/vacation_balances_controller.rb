class VacationBalancesController < ApplicationController
  before_action :require_hr_access
  before_action :set_vacation_balance, only: [:show, :edit, :update]

  def index
    @year = params[:year]&.to_i || Date.current.year
    @vacation_balances = VacationBalance.includes(:user)
                                       .joins(:user)
                                       .order('users.name ASC')

    # Apply filters
    if params[:user_ids].present?
      @vacation_balances = @vacation_balances.where(user_id: params[:user_ids])
    end

    if params[:status].present?
      case params[:status]
      when 'over_limit'
        @vacation_balances = @vacation_balances.over_limit
      when 'with_available'
        @vacation_balances = @vacation_balances.with_available_days
      else
        # No additional filtering for unknown status
      end
    end

    @pagy, @vacation_balances = pagy(@vacation_balances)
    @years = (2020..Date.current.year + 1).to_a.reverse
  end

  def show
    @user = @vacation_balance.user
    @vacation_requests = @user.vacation_requests.for_year(@vacation_balance.year)
                              .order(start_date: :desc)
  end

  def new
    @vacation_balance = VacationBalance.new
    @vacation_balance.year = Date.current.year
    @users = User.active.order(:name)
  end

  def create
    @vacation_balance = VacationBalance.new(vacation_balance_params)

    if @vacation_balance.save
      redirect_to vacation_balances_path,
                  notice: 'Balance de vacaciones creado exitosamente.'
    else
      flash[:alert] = "Error al crear la solicitud" + @vacation_balance.errors.full_messages.join(", ")
      @users = User.active.order(:name)
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @users = User.active.order(:name)
  end

  def update
    if @vacation_balance.update(vacation_balance_params)
      redirect_to @vacation_balance,
                  notice: 'Balance de vacaciones actualizado exitosamente.'
    else
      @users = User.active.order(:name)
      render :edit, status: :unprocessable_entity
    end
  end

  def by_year
    @year = params[:year]&.to_i || Date.current.year
    redirect_to vacation_balances_path(year: @year)
  end

  def recalculate_all
    year = params[:year]&.to_i || Date.current.year

    RecalculateBalancesJob.perform_later(year)

    redirect_to vacation_balances_path(year: year),
                notice: 'Recalculando balances en segundo plano. Los cambios aparecerán pronto.'
  end

  private

  def set_vacation_balance
    @vacation_balance = VacationBalance.find(params[:id])
  end

  def vacation_balance_params
    params.require(:vacation_balance).permit(:user_id, :year, :days_available, :used_days)
  end
end
