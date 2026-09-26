class CreatePins < ActiveRecord::Migration[8.1]
  def change
    # New table, so no backfill: rows only appear when a user pins something. Plain polymorphic
    # target (not delegated_type) — pin toggles carry no per-target behavior. The composite
    # unique index is the real idempotency guard; t.references already indexes [pinnable_type,
    # pinnable_id] for the reverse lookup.
    create_table :pins do |t|
      t.references :user, null: false, foreign_key: true
      t.references :pinnable, polymorphic: true, null: false

      t.timestamps
    end

    add_index :pins, [:user_id, :pinnable_type, :pinnable_id], unique: true
  end
end
