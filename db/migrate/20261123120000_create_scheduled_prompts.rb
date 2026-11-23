class CreateScheduledPrompts < ActiveRecord::Migration[8.1]
  def change
    # New table, so no backfill. next_run_at is what the every-minute dispatcher scans, so it is
    # indexed; it is null only while a prompt is paused. prompt is left unencrypted like
    # messages.content_text, which every run copies it into.
    create_table :scheduled_prompts do |t|
      t.references :user, null: false, foreign_key: true
      t.references :assistant, null: false, foreign_key: true
      t.text :prompt, null: false
      t.string :schedule, null: false
      t.string :time_zone, null: false
      t.boolean :enabled, null: false, default: true
      t.datetime :next_run_at
      t.datetime :last_run_at

      t.timestamps
    end

    add_index :scheduled_prompts, :next_run_at
  end
end
