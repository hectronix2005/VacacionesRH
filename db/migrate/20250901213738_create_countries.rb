class CreateCountries < ActiveRecord::Migration[8.0]
  def change
    create_table :countries do |t|
      t.string :name, null: false
      t.string :vacation_term, null: false
      t.integer :default_vacation_days, null: false

      t.timestamps
    end
    
    add_index :countries, :name, unique: true
    
    # Populate with initial country data
    reversible do |dir|
      dir.up do
        Country.create!(
          { name: 'Colombia', vacation_term: 'vacaciones', default_vacation_days: 15 }
        )
        Country.create!(
          { name: 'Mexico', vacation_term: 'días de descanso', default_vacation_days: 12 }
        )
      end
      
      dir.down do
        # Data will be automatically deleted when table is dropped
      end
    end
  end
end
