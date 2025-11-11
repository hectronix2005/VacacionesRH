class ModifyAndAddMoreFieldsInVacationBalances < ActiveRecord::Migration[8.0]
  def change
    add_column :vacation_balances, :worked_days, :integer, default: 0
    add_column :vacation_balances, :days_to_enjoy, :integer, default: 0
    add_column :vacation_balances, :days_available, :integer, default: 0
    add_column :vacation_balances, :days_scheduled, :integer, default: 0
  end
end
