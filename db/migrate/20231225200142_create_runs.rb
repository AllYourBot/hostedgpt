class CreateRuns < ActiveRecord::Migration[7.1]
  def change
    create_table :runs do |t|
      t.references :assistant, null: false, foreign_key: true
      t.references :conversation, null: false, foreign_key: true
      t.string :status, null: false
      t.jsonb :required_action
      t.jsonb :last_error
      t.timestamp :expired_at, null: false
      t.timestamp :started_at
      t.timestamp :cancelled_at
      t.timestamp :failed_at
      t.timestamp :completed_at
      t.string :model, null: false
      t.string :instructions, null: false
      t.string :additional_instructions
      t.jsonb :tools, null: false, default: []
      t.jsonb :file_ids, null: false, default: []

      t.timestamps
    end
  end
end
