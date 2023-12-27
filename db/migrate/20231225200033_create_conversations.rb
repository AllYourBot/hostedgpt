class CreateConversations < ActiveRecord::Migration[7.1]
  def change
    create_table :conversations do |t|
      t.references :user, null: false, foreign_key: true
      t.references :assistant, null: false, foreign_key: true
      t.string :title

      t.timestamps
    end
  end
end
