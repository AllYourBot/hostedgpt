class AddSupportsToolsToLanguageModels < ActiveRecord::Migration[7.1]
  def change
    add_column :language_models, :supports_tools, :boolean, default: false

    ActiveRecord::Base.connection.execute <<-END_SQL
      UPDATE
        language_models
      SET supports_tools = true
      WHERE
        (api_name like 'gpt%' and api_name <> 'gpt-3.5-turbo-instruct' and api_name <> 'gpt-3.5-turbo-16k-0613')  OR
        api_name like 'claude%' OR
        api_name like 'groq%' OR
        api_name like 'gemma%' OR
        api_name IN ('mixtral-8x7b-32768', 'llama3-70b-8192', 'llama3-8b-8192');
    END_SQL
  end
end
