class AddPositionToConversations < ActiveRecord::Migration[8.1]
  def change
    add_column :conversations, :position, :integer, default: 0, null: false
    add_index :conversations, [:user_id, :position]

    reversible do |dir|
      dir.up do
        # Backfill each user's existing conversations into their current visual order
        # (most recently active first) so nobody's sidebar changes shape on deploy.
        execute <<-SQL.squish
          UPDATE conversations
          SET position = subquery.new_position
          FROM (
            SELECT id,
                   ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY updated_at DESC) - 1 AS new_position
            FROM conversations
          ) AS subquery
          WHERE conversations.id = subquery.id
        SQL
      end
    end
  end
end