class AddRunReferenceToMessages < ActiveRecord::Migration[7.1]
  def change
    add_reference :messages, :run, null: true, foreign_key: true
  end
end
