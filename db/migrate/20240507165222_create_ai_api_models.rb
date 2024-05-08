class CreateAIAPIModels < ActiveRecord::Migration[7.1]
  def change
    create_table :ai_api_models do |t|
      t.string :name
      t.text :description

      t.timestamps
    end

    # Current models
    up_only do
      {
        'open_ai_newest': 'Newest OpenAI Model',
        'claude_newest': 'Newest Anthropic Model',
        'claude-3-sonnet-20240229': 'Claude 3 Sonnet',
        'gpt-4': 'ChatGPT 4',
        'claude-3-opus-20240229': 'Claude 3 Opus',
        'gpt-3.5-turbo-0125': 'ChatGPT 3.5 Turbo',
        'gpt-4-turbo-2024-04-09': 'ChatGPT 4 Turbo'
      }.each do |name, description|
        AIAPIModel.create(name: name, description: description)
      end
    end
  end
end
