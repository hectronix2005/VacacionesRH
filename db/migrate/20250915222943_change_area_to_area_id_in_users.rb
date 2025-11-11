class ChangeAreaToAreaIdInUsers < ActiveRecord::Migration[8.0]
  def change
    # Primero removemos la columna area existente
    remove_column :users, :area, :string

    # Agregamos la referencia a areas
    add_reference :users, :area, null: true, foreign_key: true
  end
end
