class User < ApplicationRecord
  ROLES = [ :employee, :leader, :hr, :admin ]

  include Roles


  has_secure_password

  # Validations
  validates :document_number, presence: true, uniqueness: true
  validates :name, presence: true
  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :country_id, presence: true
  validate :at_least_one_role

  # Relationships
  belongs_to :country
  belongs_to :area, optional: true
  belongs_to :lead, class_name: 'User', optional: true
  has_many :subordinates, class_name: 'User', foreign_key: 'lead_id'
  has_many :vacation_requests, dependent: :destroy
  has_many :vacation_balances, dependent: :destroy
  has_many :approved_requests, class_name: 'VacationRequest', foreign_key: 'approved_by_id'

  # Scopes
  scope :active, -> { where(active: true) }
  scope :by_country, ->(country_name) { joins(:country).where(countries: { name: country_name }) }
  scope :by_country_id, ->(country_id) { where(country_id: country_id) }
  scope :with_high_vacation_balance, -> {
    joins(:vacation_balances)
      .where(vacation_balances: { year: Date.current.year })
      .where('vacation_balances.days_available > ?', 10)
  }
  scope :without_vacation_this_year, -> {
    joins(:vacation_balances)
      .where(vacation_balances: { used_days: 0 })
  }

  before_save :normalize_working_days

  def destroy
    update(active: false)
  end

  # Instance methods
  def full_name
    name
  end

  def can_approve_requests?
    leader? || hr? || admin?
  end

  def can_taken_requests?
    hr? || admin?
  end

  def vacation_term
    country.vacation_term
  end

  def country_name
    country&.name
  end

  def normalize_working_days
    if self.working_days.is_a?(Hash)
      self.working_days = self.working_days.transform_values { |v| ActiveModel::Type::Boolean.new.cast(v) }
    end
  end

  # Working days methods - inherit from country if not customized
  def effective_working_days
    has_custom_working_days? ? working_days : country.working_days
  end

  def working_day?(date)
    day_name = date.strftime('%A').downcase
    return false unless effective_working_days[day_name] == true

    # Check if it's a holiday using the country's holiday calendar
    return false if country.holiday?(date)

    true
  end

  def business_days_between(start_date, end_date)
    return 0 if start_date > end_date

    count = 0
    current_date = start_date

    while current_date <= end_date
      count += 1 if working_day?(current_date)
      current_date += 1.day
    end

    count
  end

  def working_days_in_week
    %w[monday tuesday wednesday thursday friday saturday sunday].count do |day|
      effective_working_days[day] == true
    end
  end

  def has_custom_working_days?
    working_days.present? && working_days.values.any?
  end

  def uses_country_working_days?
    working_days.blank? && !working_days.values.any?
  end

  def current_year_balance
    vacation_balances.first_or_create
  end

  def available_days_for_year
    balance = vacation_balances.first_or_create

    balance.days_available
  end

  def has_pending_requests?
    vacation_requests.pending.any?
  end

  def vacation_usage_percentage
    balance = vacation_balances.first_or_create
    return 0 unless balance && balance.days_available > 0

    (balance.used_days.to_f / balance.days_available * 100).round(1)
  end

  # Check if user needs vacation alert for HR
  def needs_vacation_alert?
    available_days_for_year > 10 || (current_year_balance&.used_days == 0 && Date.current.month > 6)
  end

  # Get user initials for avatar
  def initials
    name.split.map(&:first).join.upcase[0, 2]
  end

  # Métodos para cálculo de vacaciones basado en fecha de ingreso
  def years_of_service(reference_date = Date.current)
    return 0 if hire_date.blank?

    years = reference_date.year - hire_date.year
    years -= 1 if reference_date < hire_date + years.years
    years
  end

  def worked_days
    return 0 if hire_date.blank?

    @days ||= days_360(hire_date, Date.today + 1.day)
  end

  def days_to_enjoy
    return 0 if hire_date.blank?

    worked_days / 24
  end

  def calculate_vacation_days_for_year(year = Date.current.year)
    return 0 if hire_date.blank?

    # Fecha de referencia para el cálculo (31 de diciembre del año en cuestión)
    year_end = Date.new(year, 12, 31)

    # Si el usuario fue contratado después del año en cuestión, no tiene días
    return 0 if hire_date.year > year

    years_at_year_end = years_of_service(year_end)

    # Si el usuario ya completó un año o más, recibe el total de días
    if years_at_year_end >= 1
      return country.default_vacation_days
    else
      ((Date.current - hire_date).to_i / 24).round
    end
  end

  private

  def days_360(start_date, end_date)
    start_day = start_date.day
    start_month = start_date.month
    start_year = start_date.year

    end_day = end_date.day
    end_month = end_date.month
    end_year = end_date.year

    start_day = 30 if start_day == 31
    end_day = 30 if end_day == 31

    (end_year - start_year) * 360 + (end_month - start_month) * 30 + (end_day - start_day)
  end
  def at_least_one_role
    errors.add(:base, I18n.t('users.errors.at_least_one_role')) if active_roles.empty?
  end
end
