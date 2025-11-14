class AddPerformanceIndexes < ActiveRecord::Migration[8.0]
  def change
    # Indexes for Users table
    add_index :users, :lead_id, if_not_exists: true
    add_index :users, :country_id, if_not_exists: true
    add_index :users, :area_id, if_not_exists: true
    add_index :users, [:active, :lead_id], if_not_exists: true
    add_index :users, [:active, :country_id], if_not_exists: true

    # Indexes for Vacation Requests table
    add_index :vacation_requests, :user_id, if_not_exists: true
    add_index :vacation_requests, :status, if_not_exists: true
    add_index :vacation_requests, [:user_id, :status], if_not_exists: true
    add_index :vacation_requests, [:status, :created_at], if_not_exists: true
    add_index :vacation_requests, [:start_date, :end_date], if_not_exists: true
    add_index :vacation_requests, :approved_by_id, if_not_exists: true

    # Indexes for Vacation Balances table
    add_index :vacation_balances, :user_id, if_not_exists: true
    add_index :vacation_balances, [:user_id, :year], if_not_exists: true
    add_index :vacation_balances, :year, if_not_exists: true

    # Indexes for Vacation Approvals table
    add_index :vacation_approvals, :vacation_request_id, if_not_exists: true
    add_index :vacation_approvals, :user_id, if_not_exists: true

    # Indexes for Areas table
    add_index :areas, :name, if_not_exists: true

    # Composite indexes for common queries
    add_index :vacation_requests, [:user_id, :status, :created_at],
              name: 'index_vacation_requests_on_user_status_created',
              if_not_exists: true
  end
end
