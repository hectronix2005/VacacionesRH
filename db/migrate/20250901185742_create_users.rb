class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :document_number
      t.string :phone
      t.string :name
      t.string :country
      t.string :password_digest
      t.boolean :active
      t.references :lead, foreign_key: { to_table: :users }, null: true
      if t.respond_to? :jsonb
        t.jsonb :roles, null: false, default: {}
      else
        t.json :roles
      end

      t.timestamps
    end
    add_index :users, :document_number, unique: true
  end
end
