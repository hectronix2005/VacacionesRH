class Area < ApplicationRecord
  # Validations
  validates :name, presence: true, uniqueness: true

  # Relationships
  has_many :users, dependent: :restrict_with_error
  has_many :vacation_requests, through: :users

  # Scopes
  scope :ordered, -> { order(:name) }

  # Instance methods
  def to_s
    name
  end

  def users_count
    users.count
  end

  def active_users_count
    users.active.count
  end
end
