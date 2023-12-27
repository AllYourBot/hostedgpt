class AddDocumentReferenceToMessages < ActiveRecord::Migration[7.1]
  def change
    add_reference :messages, :content_document, null: true, foreign_key: {to_table: :documents}
  end
end
