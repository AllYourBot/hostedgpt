class CreateScheduledPrompts < ActiveRecord::Migration[8.1]
  def change
    # prompt stays unencrypted: every run copies it into messages.content_text, which is not encrypted either.
    create_table :scheduled_prompts do |t|
      t.references :user, null: false, foreign_key: true
      t.references :assistant, null: false, foreign_key: true
      t.text :prompt, null: false
      t.string :schedule, null: false
      t.string :time_zone, null: false
      t.boolean :enabled, null: false, default: true
      t.datetime :next_run_at
      t.datetime :last_run_at
      t.integer :consecutive_failures, null: false, default: 0

      t.timestamps
    end

    add_index :scheduled_prompts, :next_run_at

    add_reference :conversations, :scheduled_prompt, foreign_key: true
    add_column :conversations, :unread, :boolean, null: false, default: false
  end
end
