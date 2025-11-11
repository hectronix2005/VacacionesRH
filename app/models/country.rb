class Country < ApplicationRecord
  # Relationships
  has_many :users, dependent: :restrict_with_error

  # Validations
  validates :name, presence: true, uniqueness: true
  validates :vacation_term, presence: true
  validates :default_vacation_days, presence: true,
                                    numericality: { greater_than: 0, less_than_or_equal_to: 30 }

  before_create :ensure_working_days_present
  before_create :ensure_vacation_term_present

  # Scopes
  scope :active, -> { joins(:users).where(users: { active: true }).distinct }

  # Class methods
  def self.colombia
    find_by(name: 'Colombia')
  end

  def self.mexico
    find_by(name: 'Mexico')
  end

  # Instance methods
  def uses_rest_days?
    name == 'Mexico'
  end

  def display_name
    name
  end

  def vacation_term_title
    vacation_term.titleize
  end

  # Working days methods
  def working_day?(date)
    day_name = date.strftime('%A').downcase
    return false unless working_days[day_name] == true

    # Check if it's a holiday using the holidays gem
    return false if holiday?(date)

    true
  end

  def holiday?(date)
    return false if g_country.blank?

    Holidays.on(date, g_country.to_sym).any?
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
      working_days[day] == true
    end
  end

  private

  def ensure_working_days_present
    return if working_days.present?

    self.working_days = {
      monday: true,
      tuesday: true,
      wednesday: true,
      thursday: true,
      friday: true,
      saturday: false,
      sunday: false
    }
  end

  def ensure_vacation_term_present
    return if vacation_term.present?

    self.vacation_term = "vacaciones"
  end

  def ensure_default_vacation_days_present
    return if default_vacation_days.present?

    self.default_vacation_days = 15
  end
end
