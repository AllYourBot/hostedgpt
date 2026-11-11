class CreateConnectors < ActiveRecord::Migration[8.1]
  def change
    create_table :connectors do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :url, null: false
      t.string :token
      t.jsonb :tools, default: [], null: false, comment: "The tools the MCP server listed when the connector was last saved"
      t.jsonb :disabled_tool_names, default: [], null: false
      t.timestamps
    end
  end
end
