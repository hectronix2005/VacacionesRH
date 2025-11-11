class UserStatsService
  def initialize(user)
    @user = user
  end

  def generate_stats
    {
      personal_stats: personal_vacation_stats,
      team_stats: team_stats_if_leader,
      hr_stats: hr_stats_if_applicable,
      alerts: generate_alerts
    }
  end

  private

  def personal_vacation_stats
    balance = @user.current_year_balance
    return default_stats unless balance

    {
      days_available: balance.days_available,
      used_days: balance.used_days,
      available_days: balance.days_available,
      usage_percentage: (@user.vacation_usage_percentage).round(1),
      vacation_term: @user.vacation_term,
      pending_requests: @user.vacation_requests.pending.count
    }
  end

  def team_stats_if_leader
    return {} unless @user.leader? || @user.admin?

    subordinates = @user.subordinates.active
    {
      team_size: subordinates.count,
      team_pending_requests: subordinates.joins(:vacation_requests)
                                        .where(vacation_requests: { status: 'pending' })
                                        .count,
      team_high_balances: subordinates.select(&:needs_vacation_alert?).count
    }
  end

  def hr_stats_if_applicable
    return default_hr_stats unless @user.hr? || @user.admin?

    users_needing_attention = User.active.select(&:needs_vacation_alert?) || []

    {
      total_users: User.active.count,
      pending_approvals: VacationRequest.pending.count,
      users_with_alerts: users_needing_attention.count,
      users_needing_attention: users_needing_attention,
      recent_requests: VacationRequest.recent.limit(5),
      countries_summary: countries_summary
    }
  end

  def generate_alerts
    alerts = []

    # Alertas personales
    if @user.needs_vacation_alert?
      alerts << {
        type: 'warning',
        message: "Tienes #{@user.available_days_for_year} días de #{@user.vacation_term} acumulados",
        action: 'Solicitar vacaciones',
        url: '/vacation_requests/new'
      }
    end

    # Alertas de equipo para líderes
    if @user.admin? || @user.leader?
      pending_team_requests = @user.subordinates.joins(:vacation_requests)
                                   .where(vacation_requests: { status: 'pending' })
                                   .count
      if pending_team_requests > 0
        alerts << {
          type: 'info',
          message: "Tienes #{pending_team_requests} solicitud(es) de tu equipo por aprobar",
          action: 'Ver solicitudes',
          url: '/vacation_requests/pending'
        }
      end
    end

    # Alertas de RH
    if @user.hr? || @user.admin?
      total_pending = VacationRequest.pending.count
      if total_pending > 0
        alerts << {
          type: 'info',
          message: "Hay #{total_pending} solicitud(es) pendientes en el sistema",
          action: 'Gestionar solicitudes',
          url: '/vacation_requests/pending'
        }
      end
    end

    alerts
  end

  def countries_summary
    Country.joins(:users)
           .where(users: { active: true })
           .group('countries.name')
           .count
  end

  def default_stats
    {
      days_available: 0,
      used_days: 0,
      available_days: 0,
      usage_percentage: 0,
      vacation_term: @user.vacation_term,
      pending_requests: 0
    }
  end

  def default_hr_stats
    {
      total_users: 0,
      pending_approvals: 0,
      users_with_alerts: 0,
      users_needing_attention: [],
      recent_requests: [],
      countries_summary: {}
    }
  end
end

