class AddUniqueIndexesForEmailsAndExternalId < ActiveRecord::Migration[7.1]
  def change
    add_index :people, [:email], unique: true
    add_index :credentials, [:type, :external_id], unique: true
    add_index :credentials, [:type, :oauth_email], unique: true
  end
end
