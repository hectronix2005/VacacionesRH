class CreateVacationRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :vacation_requests do |t|
      t.references :user, null: false, foreign_key: true
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.integer :days_requested, null: false
      t.integer :status, default: 0, null: false
      t.text :reason
      t.references :approved_by, null: true, foreign_key: { to_table: :users }
      t.datetime :approved_at
      t.text :rejected_reason

      t.timestamps
    end
    
    add_index :vacation_requests, :status
    add_index :vacation_requests, [:user_id, :start_date]
  end
end
