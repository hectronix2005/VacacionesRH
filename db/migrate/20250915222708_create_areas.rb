class CreateAreas < ActiveRecord::Migration[8.0]
  def change
    create_table :areas do |t|
      t.string :name, null: false

      t.timestamps
    end

    add_index :areas, :name, unique: true
  end
end
