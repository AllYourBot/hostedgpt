class CreateMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :messages do |t|
      t.text :content
      t.references :chat, null: false, foreign_key: true
      t.integer :parent_id

      t.timestamps
    end
    add_index :messages, :parent_id
  end
end
