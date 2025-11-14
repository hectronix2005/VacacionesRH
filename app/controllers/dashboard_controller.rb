class DashboardController < ApplicationController
  include UserManagement

  def index
    @stats = user_dashboard_stats
    @navigation = navigation_items_for_user

    # Cargar datos específicos según el rol usando el patrón Strategy
    @dashboard_data = load_role_specific_data
  end

  private

  def load_role_specific_data
    if current_user.employee?
      load_employee_dashboard_data
    elsif current_user.leader?
      load_leader_dashboard_data
    elsif current_user.hr? || current_user.admin?
      load_hr_dashboard_data
    end
  end

  def load_employee_dashboard_data
    balance = current_user.current_year_balance
    return default_employee_data unless balance

    used_days = balance.used_days
    days_available = balance.days_available
    {
      pending_requests: current_user.vacation_requests.pending.count,
      used_days: used_days,
      days_available: days_available,
      usage_percentage: days_available.zero? ? 0 : (used_days.to_f / days_available.to_f) * 100,
    }
  end

  def default_employee_data
    {
      pending_requests: 0,
      used_days: 0,
      days_available: 0,
      usage_percentage: 0
    }
  end

  def load_leader_dashboard_data
    subordinates = current_user.subordinates.active.includes(:vacation_balances)

    {
      team_requests_pending: VacationRequest.joins(:user)
                                           .where(users: { lead_id: current_user.id })
                                           .pending
                                           .count,
      team_size: subordinates.count,
      team_members_with_alerts: subordinates.count { |s| s.needs_vacation_alert? }
    }
  end

  def load_hr_dashboard_data
    {
      total_pending_requests: VacationRequest.pending.count,
      total_users: User.active.count,
      users_needing_attention: User.active.with_high_vacation_balance.count,
      recent_new_users: User.active.includes(:country, :area).order(created_at: :desc).limit(5),
      monthly_stats: monthly_vacation_stats,
      country_distribution: Country.joins(:users)
                                   .where(users: { active: true })
                                   .group('countries.name')
                                   .count
    }
  end

  def monthly_vacation_stats
    current_month = Date.current.beginning_of_month..Date.current.end_of_month

    {
      requests_this_month: VacationRequest.where(created_at: current_month).count,
      approved_this_month: VacationRequest.approved.where(created_at: current_month).count,
      users_on_vacation: VacationRequest.approved
                                       .where('start_date <= ? AND end_date >= ?',
                                              Date.current, Date.current)
                                       .count
    }
  end
end
