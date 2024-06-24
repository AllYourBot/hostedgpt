class CreateMemories < ActiveRecord::Migration[7.1]
  def change
    drop_table :memories if table_exists?(:memories)
    create_table :memories do |t|
      t.references :user, null: false, foreign_key: true
      t.references :message, null: true, foreign_key: true
      t.string :detail

      t.timestamps
    end
  end
end
