class CreateVacationBalances < ActiveRecord::Migration[8.0]
  def change
    create_table :vacation_balances do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :year, null: false, default: 0
      t.integer :total_days, null: false, default: 0
      t.integer :used_days, default: 0

      t.timestamps
    end

    add_index :vacation_balances, [:user_id, :year], unique: true
  end
end
