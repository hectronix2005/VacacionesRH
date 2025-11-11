class AddWorkingDaysToUsers < ActiveRecord::Migration[8.0]
  def change
    # Add working_days column to users (nullable to allow inheritance from country)
    add_column :users, :working_days, :jsonb, default: default_working_days
  end

  def default_working_days
    {
      monday: false,
      tuesday: false,
      wednesday: false,
      thursday: false,
      friday: false,
      saturday: false,
      sunday: false
    }
  end
end
