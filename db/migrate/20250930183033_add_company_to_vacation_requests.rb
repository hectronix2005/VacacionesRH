class AddCompanyToVacationRequests < ActiveRecord::Migration[8.0]
  def change
    add_column :vacation_requests, :company, :string, default: ''
  end
end
