class CreateTombstones < ActiveRecord::Migration[7.1]
  def change
    create_table :tombstones do |t|
      t.references :person, null: false, foreign_key: true
      t.datetime :deleted_at

      t.timestamps
    end
  end
end
