class AddPositionToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :position, :string, default: ''
  end
end
