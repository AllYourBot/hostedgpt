class CreateAPIServices < ActiveRecord::Migration[7.1]
  def change
    create_table :api_services do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :driver, null: false, comment: "What API spec does this service conform to, e.g. OpenAI or Anthropic"
      t.string :url, null: false
      t.string :token, null: true
      t.timestamp :deleted_at, null: true, default: nil

      t.timestamps
    end
    add_index :api_services, [:user_id, :deleted_at]
  end
end
