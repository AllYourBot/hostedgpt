class CreateClients < ActiveRecord::Migration[7.1]
  def change
    create_table :clients do |t|
      t.references :person, null: false, foreign_key: true
      t.string :token, null: false
      t.string :platform
      t.string :format
      t.string :user_agent
      t.string :ip_address
      t.integer :time_zone_offset_in_minutes

      t.timestamps
    end
    add_index :clients, :token, unique: true
  end
end
