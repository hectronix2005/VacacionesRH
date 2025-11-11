module UsersHelper
  # Generate vacation alerts for HR dashboard
  def vacation_alerts_for_user(user)
    alerts = []
    available_days = user.available_days_for_year
    vacation_balance = user.current_year_balance

    return alerts unless vacation_balance

    # Alert for high accumulated vacation days
    if available_days > 15
      alerts << {
        type: 'warning',
        icon: 'exclamation-triangle',
        message: "#{user.name} tiene #{available_days} días de #{user.vacation_term} acumulados",
        priority: 'high'
      }
    elsif available_days > 10
      alerts << {
        type: 'info',
        icon: 'info-circle',
        message: "#{user.name} tiene #{available_days} días de #{user.vacation_term} disponibles",
        priority: 'medium'
      }
    end

    # Alert for pending requests
    pending_requests = user.vacation_requests.pending.count
    if pending_requests > 0
      alerts << {
        type: 'info',
        icon: 'clock',
        message: "#{user.name} tiene #{pending_requests} solicitud(es) pendiente(s) de aprobación",
        priority: 'medium'
      }
    end

    # Alert for users who haven't taken vacation this year
    if vacation_balance.used_days == 0 && Date.current.month > 6
      alerts << {
        type: 'warning',
        icon: 'calendar-times',
        message: "#{user.name} no ha tomado #{user.vacation_term} este año",
        priority: 'medium'
      }
    end

    alerts
  end

  # Format role for display
  def format_user_role(role)
    case role
    when 'employee'
      'Empleado'
    when 'leader'
      'Líder de Equipo'
    when 'hr'
      'Recursos Humanos'
    else
      role.humanize
    end
  end

  # Get status badge class
  def user_status_badge_class(user)
    if user.active?
      'bg-green-100 text-green-800'
    else
      'bg-red-100 text-red-800'
    end
  end

  # Get country-specific information
  def country_specific_info(user)
    return {} unless user.country

    case user.country.name
    when 'México'
      {
        contract_type: 'Prestación de Servicios',
        vacation_term: 'días de descanso',
        legal_framework: 'Contrato de prestación de servicios',
        badge_color: 'bg-orange-100 text-orange-800'
      }
    when 'Colombia'
      {
        contract_type: 'Laboral',
        vacation_term: 'vacaciones',
        legal_framework: 'Código Sustantivo del Trabajo',
        badge_color: 'bg-blue-100 text-blue-800'
      }
    else
      {
        contract_type: 'Laboral',
        vacation_term: 'vacaciones',
        legal_framework: 'Legislación local',
        badge_color: 'bg-gray-100 text-gray-800'
      }
    end
  end

  # Calculate vacation usage percentage
  def vacation_usage_percentage(user)
    balance = user.current_year_balance
    return 0 unless balance && balance.days_available > 0

    (balance.used_days.to_f / balance.days_available * 100).round(1)
  end

  # Get usage status color
  def usage_status_color(percentage)
    case percentage
    when 0..25
      'text-red-600'
    when 26..50
      'text-yellow-600'
    when 51..75
      'text-blue-600'
    else
      'text-green-600'
    end
  end

  # Format document number for display
  def format_document_number(document_number, country)
    return document_number unless country

    case country.name
    when 'Colombia'
      # Format Colombian cedula with dots
      document_number.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1.').reverse
    when 'México'
      # Keep Mexican documents as-is
      document_number
    else
      document_number
    end
  end

  # Generate user initials for avatar
  def user_initials(name)
    name.split.map(&:first).join.upcase[0, 2]
  end

  def role_label(role)
    I18n.t("users.roles.#{role}", default: role.to_s.humanize)
  end

  def role_badge_class(role)
    case role.to_sym
    when :employee then 'bg-green-100 text-green-800'
    when :leader then 'bg-yellow-100 text-yellow-800'
    when :hr then 'bg-purple-100 text-purple-800'
    when :admin then 'bg-red-100 text-red-800'
    else 'bg-gray-100 text-gray-800'
    end
  end

  def role_badges_for(user)
    user.active_roles.map do |r|
      content_tag(:span, role_label(r), class: "inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium #{role_badge_class(r)} mr-1 mb-1")
    end.join.html_safe
  end
end
