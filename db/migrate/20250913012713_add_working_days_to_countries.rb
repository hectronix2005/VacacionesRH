class AddWorkingDaysToCountries < ActiveRecord::Migration[8.0]
  def up
    # Add working_days column with default value
    add_column :countries, :working_days, :jsonb, default: default_working_days
    
    # Update existing countries with default working days
    Country.reset_column_information
    Country.find_each do |country|
      country.update!(working_days: default_working_days) if country.working_days.blank?
    end
  end

  def down
    remove_column :countries, :working_days
  end

  private

  def default_working_days
    {
      monday: true,
      tuesday: true,
      wednesday: true,
      thursday: true,
      friday: true,
      saturday: false,
      sunday: false
    }
  end
end
