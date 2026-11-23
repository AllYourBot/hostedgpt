class TrackScheduledPromptFailures < ActiveRecord::Migration[8.1]
  def change
    add_reference :conversations, :scheduled_prompt, foreign_key: true
    add_column :scheduled_prompts, :consecutive_failures, :integer, default: 0, null: false
  end
end
