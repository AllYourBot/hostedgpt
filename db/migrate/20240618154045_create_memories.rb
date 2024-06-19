class CreateMemories < ActiveRecord::Migration[7.1]
  def change
    create_table :memories do |t|
      t.references :user, null: false, foreign_key: true
      t.references :message, null: true, foreign_key: true
      t.string :detail

      t.timestamps
    end
  end
end
