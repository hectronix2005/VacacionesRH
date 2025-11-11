class VacationBalanceCalculator
  def self.calculate_for_user(user, year = Date.current.year)
    return 0 if user.hire_date.blank?

    # Si el usuario fue contratado después del año, no tiene días
    return 0 if user.hire_date.year > year

    user.calculate_vacation_days_for_year(year)
  end

  def self.update_all_balances
    User.active.includes(:country, :vacation_balances).find_each do |user|
      balance = user.vacation_balances.first_or_create

      days_scheduled = user.vacation_requests
                           .approved
                           .sum(:days_requested)

      used_days = user.vacation_requests
                      .taken
                      .sum(:days_requested)

      # Mantener los días usados si ya existía el balance
      used_days = used_days
      days_to_enjoy = user.days_to_enjoy
      days_available = user.days_to_enjoy - used_days - days_scheduled
      days_scheduled = days_scheduled
      worked_days = user.worked_days

      balance.assign_attributes(
        worked_days: worked_days,
        days_to_enjoy: days_to_enjoy,
        days_available: days_available,
        days_scheduled: days_scheduled,
        used_days: used_days
      )
      balance.save
    end
  end

  def self.create_missing_balances
    users_without_balance = User.active
                               .left_joins(:vacation_balances)
                               .where(vacation_balances: { id: nil })
    year = Date.current.year

    users_without_balance.find_each do |user|
      next if user.hire_date.blank? || user.hire_date.year > year

      user.vacation_balances.first_or_create do |balance|
        balance.used_days = 0
        balance.worked_days = user.worked_days
        balance.days_to_enjoy = user.days_to_enjoy
        balance.days_available = 0
        balance.days_scheduled = 0
        balance.save
      end
    end
  end
end
