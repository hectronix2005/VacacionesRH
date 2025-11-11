class CreateVacationApprovalConfigs < ActiveRecord::Migration[8.0]
  def change
    create_table :vacation_approval_configs do |t|
      t.string :role, null: false
      t.boolean :required, default: true
      t.integer :order_position, default: 0
      t.boolean :active, default: true
      t.text :description
      t.integer :minimum_approvals, default: 1

      t.timestamps
    end

    add_index :vacation_approval_configs, :role, unique: true
    add_index :vacation_approval_configs, :order_position
    add_index :vacation_approval_configs, :active
  end
end
