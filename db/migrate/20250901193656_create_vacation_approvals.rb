class CreateVacationApprovals < ActiveRecord::Migration[8.0]
  def change
    create_table :vacation_approvals do |t|
      t.references :vacation_request, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :role, null: false
      t.integer :status, default: 0, null: false
      t.datetime :approved_at
      t.text :comments

      t.timestamps
    end
    
    # Ensure one approval per role per vacation request
    add_index :vacation_approvals, [:vacation_request_id, :role], unique: true
    add_index :vacation_approvals, :approved_at
  end
end
