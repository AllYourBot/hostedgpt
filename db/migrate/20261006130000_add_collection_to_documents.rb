class AddCollectionToDocuments < ActiveRecord::Migration[8.1]
  def change
    add_reference :documents, :collection, foreign_key: true
  end
end
