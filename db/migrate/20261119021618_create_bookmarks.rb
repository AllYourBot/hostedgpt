class CreateBookmarks < ActiveRecord::Migration[8.1]
  def change
    # New table, so no backfill: rows only appear when a user bookmarks something. Plain
    # polymorphic target (not delegated_type) — bookmark toggles carry no per-target behavior.
    # The composite unique index is the real idempotency guard; t.references already indexes
    # [bookmarkable_type, bookmarkable_id] for the reverse lookup. No position column lives
    # here: bookmarking never touches order, unlike pinning.
    create_table :bookmarks do |t|
      t.references :user, null: false, foreign_key: true
      t.references :bookmarkable, polymorphic: true, null: false

      t.timestamps
    end

    add_index :bookmarks, [:user_id, :bookmarkable_type, :bookmarkable_id],
      unique: true, name: "index_bookmarks_on_user_and_bookmarkable"
  end
end
