class CreateDocuments < ActiveRecord::Migration[7.1]
  def change
    create_table :documents do |t|
      t.references :user, null: false, foreign_key: true
      t.references :assistant, foreign_key: true
      t.references :message, foreign_key: true
      t.string :filename, null: false
      t.string :purpose, null: false
      t.integer :bytes, null: false

      t.timestamps
    end
  end
end
