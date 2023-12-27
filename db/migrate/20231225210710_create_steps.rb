class CreateSteps < ActiveRecord::Migration[7.1]
  def change
    create_table :steps do |t|
      t.references :assistant, null: false, foreign_key: true
      t.references :conversation, null: false, foreign_key: true
      t.references :run, null: false, foreign_key: true
      t.string :kind, null: false
      t.string :status, null: false
      t.jsonb :details, null: false
      t.jsonb :last_error
      t.timestamp :expired_at
      t.timestamp :cancelled_at
      t.timestamp :failed_at
      t.timestamp :completed_at

      t.timestamps
    end
  end
end
