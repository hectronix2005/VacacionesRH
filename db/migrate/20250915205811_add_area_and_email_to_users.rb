class AddAreaAndEmailToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :area, :string
    add_column :users, :email, :string
  end
end
