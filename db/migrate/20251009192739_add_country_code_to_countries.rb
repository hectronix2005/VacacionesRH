class AddCountryCodeToCountries < ActiveRecord::Migration[8.0]
  def change
    add_column :countries, :g_country, :string
    add_index :countries, :g_country, unique: true
  end
end
