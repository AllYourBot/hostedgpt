class AddContentCitationsToMessages < ActiveRecord::Migration[8.1]
  def change
    add_column :messages, :content_citations, :jsonb
  end
end
