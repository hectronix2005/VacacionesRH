class AddCompanyToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :company, :string, default: ''
  end
end
