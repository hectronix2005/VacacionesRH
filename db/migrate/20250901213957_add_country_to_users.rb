class AddCountryToUsers < ActiveRecord::Migration[8.0]
  def up
    # Add country_id column as nullable first
    add_reference :users, :country, null: true, foreign_key: true
    
    # Migrate existing data from string country to country_id
    execute <<-SQL
      UPDATE users 
      SET country_id = (
        SELECT id FROM countries WHERE name = users.country
      )
      WHERE country IS NOT NULL;
    SQL
    
    # Make country_id not null after data migration
    change_column_null :users, :country_id, false
    
    # Remove the old country string column
    remove_column :users, :country, :string
  end
  
  def down
    # Add back the country string column
    add_column :users, :country, :string
    
    # Migrate data back from country_id to string
    execute <<-SQL
      UPDATE users 
      SET country = (
        SELECT name FROM countries WHERE id = users.country_id
      )
      WHERE country_id IS NOT NULL;
    SQL
    
    # Add back the country validation constraint
    execute <<-SQL
      UPDATE users SET country = 'Colombia' WHERE country IS NULL;
    SQL
    
    change_column_null :users, :country, false
    
    # Remove the country_id reference
    remove_reference :users, :country, foreign_key: true
  end
end
