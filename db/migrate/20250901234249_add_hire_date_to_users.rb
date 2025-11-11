class AddHireDateToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :hire_date, :date
  end
end
