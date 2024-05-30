class CreateAPIServices < ActiveRecord::Migration[7.1]
  def change
    create_table :api_services do |t|
      t.bigint :user_id
      t.string :name, null: false
      t.string :url, null: false
      t.string :access_token, null: true
      t.timestamp :deleted_at, null: true, default: nil

      t.timestamps
    end
    add_index :api_services, [:user_id, :deleted_at]
  end
end
