class CreateReactions < ActiveRecord::Migration[8.1]
  def change
    # New table, so no backfill: rows only appear when a user reacts to something. Plain
    # polymorphic target (not delegated_type) — reaction toggles carry no per-target behavior.
    # The composite unique index is the real idempotency guard; t.references already indexes
    # [reactable_type, reactable_id] for the reverse lookup. No position column lives
    # here: reacting never touches order, unlike pinning.
    create_table :reactions do |t|
      t.references :user, null: false, foreign_key: true
      t.references :reactable, polymorphic: true, null: false
      t.string :emoji, null: false

      t.timestamps
    end

    add_index :reactions, [:user_id, :reactable_type, :reactable_id, :emoji],
      unique: true, name: "index_reactions_on_user_and_reactable_and_emoji"
  end
end
