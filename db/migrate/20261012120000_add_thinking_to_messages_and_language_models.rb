class AddThinkingToMessagesAndLanguageModels < ActiveRecord::Migration[8.1]
  def change
    add_column :messages, :thinking_text, :text
    add_column :messages, :thinking_signature, :text
    add_column :language_models, :supports_thinking, :boolean, default: false, null: false

    reversible do |dir|
      dir.up do
        # Claude models that take adaptive thinking on the Anthropic API.
        execute <<-END_SQL
          UPDATE language_models
          SET supports_thinking = true
          WHERE api_name LIKE 'claude-opus-4-6%' OR
            api_name LIKE 'claude-sonnet-4-6%' OR
            api_name LIKE 'claude-opus-4-7%' OR
            api_name LIKE 'claude-opus-4-8%' OR
            api_name LIKE 'claude-opus-5%' OR
            api_name LIKE 'claude-sonnet-5%' OR
            api_name LIKE 'claude-haiku-5%' OR
            api_name LIKE 'claude-fable-5%';
        END_SQL
      end
    end
  end
end
