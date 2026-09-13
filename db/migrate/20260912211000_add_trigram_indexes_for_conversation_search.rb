class AddTrigramIndexesForConversationSearch < ActiveRecord::Migration[8.1]
  def change
    # The sidebar's search matches anywhere inside the text (ILIKE '%query%'), which a regular
    # btree index cannot serve — Postgres would read every message on every search. Trigram
    # indexes chop the text into 3-character fragments and index those, so unanchored matches
    # become index lookups.
    enable_extension "pg_trgm"

    add_index :messages, :content_text, using: "gin", opclass: { content_text: :gin_trgm_ops }
    add_index :conversations, :title, using: "gin", opclass: { title: :gin_trgm_ops }
  end
end
