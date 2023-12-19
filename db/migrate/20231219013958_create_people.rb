class CreatePeople < ActiveRecord::Migration[7.1]
  def change
    create_table :people do |t|
      t.references :personable, polymorphic: true
      t.string :email

      t.timestamps
    end
  end
end
