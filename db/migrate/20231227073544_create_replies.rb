class CreateReplies < ActiveRecord::Migration[7.1]
  def change
    create_table :replies do |t|
      t.text :content
      t.references :note, null: false, foreign_key: true

      t.timestamps
    end
  end
end
