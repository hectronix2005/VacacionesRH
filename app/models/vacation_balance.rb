class VacationBalance < ApplicationRecord
  belongs_to :user

  # Scopes
  scope :with_available_days, -> { where('days_available > used_days') }
  scope :over_limit, -> { where('used_days > days_available') }

  # Instance methods
  def available_days
    days_available
  end
end
