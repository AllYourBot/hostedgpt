class CreateClients < ActiveRecord::Migration[7.1]
  def change
    drop_table :clients if table_exists?(:clients)
    create_table :clients do |t|
      t.references :person, null: false, foreign_key: true
      t.string :token, null: false, comment: "Auto-generated by rails and saved in browser cookie"
      t.string :platform, comment: "e.g. ios android web"
      t.string :user_agent
      t.string :ip_address

      t.timestamps
    end
    add_index :clients, :token, unique: true
  end
end
