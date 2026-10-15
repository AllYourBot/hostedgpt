class AddPositionToConversations < ActiveRecord::Migration[8.1]
  def change
    # Nullable, like assistants.position: Reorderable assigns new records' positions in Ruby, and
    # the backfill below decides what every existing row's position is.
    add_column :conversations, :position, :integer
    add_index :conversations, [:user_id, :position]

    reversible do |dir|
      dir.up do
        # Backfill each user's existing conversations into their current visual order — most
        # recently active first, ties broken the way the old ordered scope broke them — so
        # nobody's sidebar changes shape on deploy.
        execute <<-SQL.squish
          UPDATE conversations
          SET position = subquery.new_position
          FROM (
            SELECT id,
                   ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY updated_at DESC, id DESC) - 1 AS new_position
            FROM conversations
          ) AS subquery
          WHERE conversations.id = subquery.id
        SQL
      end
    end
  end
end

