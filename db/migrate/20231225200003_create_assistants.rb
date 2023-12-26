class CreateAssistants < ActiveRecord::Migration[7.1]
  def change
    create_table :assistants do |t|
      t.references :user, null: false, foreign_key: true
      t.string :model
      t.string :name
      t.string :description
      t.string :instructions
      t.jsonb :tools, null: false, default: []

      t.timestamps
    end
  end
end
