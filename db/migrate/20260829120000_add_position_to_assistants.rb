class AddPositionToAssistants < ActiveRecord::Migration[8.1]
  def up
    add_column :assistants, :position, :integer
    add_index :assistants, [:user_id, :position]

    # The list was ordered newest-first until now. Freeze that into position so nobody's sidebar
    # rearranges itself the first time they load the page after this migration.
    execute <<~SQL
      UPDATE assistants
      SET position = ordering.position
      FROM (
        SELECT id, ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY id DESC) - 1 AS position
        FROM assistants
      ) AS ordering
      WHERE assistants.id = ordering.id
    SQL
  end

  def down
    remove_column :assistants, :position
  end
end
