class CreateLanguageModels < ActiveRecord::Migration[7.1]
  def change
    create_table :language_models do |t|
      t.string :name
      t.text :description

      t.timestamps
    end

    # Current models
    up_only do
      {
        'open_ai_best': 'Best OpenAI Model',
        'claude_best': 'Best Anthropic Model',

        'gpt-4': 'ChatGPT 4',
        'gpt-4-turbo': 'ChatGPT 4 Turbo with Vision (may update)',
        'gpt-4-turbo-2024-04-09': 'ChatGPT-4 Turbo with Vision (2024-04-09)',
        'gpt-4-turbo-preview': 'ChatGPT 4 Turbo Preview',
        'gpt-4-0125-preview': 'ChatGPT 4 Turbo Preview (2024-01-25)',
        'gpt-4-1106-preview': 'ChatGPT 4 Turbo Preview (2023-11-06)',
        'gpt-4-vision-preview': 'ChatGPT 4 Turbo Model preview with the ability to understand images',
        'gpt-4-1106-vision-preview': 'ChatGPT 4 Turbo Model preview with the ability to understand images (2023-11-06)',
        'gpt-4-0613': 'ChatGPT 4 Snapshot improved function calling (2023-06-13)',

        'gpt-3.5-turbo': 'ChatGPT 3.5 Turbo',
        'gpt-3.5-turbo-16k-0613': 'ChatGPT 3.5 Turbo (2023-06-13)',
        'gpt-3.5-turbo-0125': 'ChatGPT 3.5 Turbo (2023-01-25)',
        'gpt-3.5-turbo-instruct': 'ChatGPT 3.5 Turbo Instruct',

        'claude-3-opus-20240229': 'Claude 3 Opus (2024-02-29)',
        'claude-3-sonnet-20240229': 'Claude 3 Sonnet (2024-02-29)',
        'claude-3-haiku-20240307': 'Claude 3 Haiku (2024-03-07)',
        'claude-2.1': 'Claude 2.1',
        'claude-2.0': 'Claude 2.0',
        'claude-instant-1.2': 'Claude Instant 1.2'
      }.each do |name, description|
        LanguageModel.create(name: name, description: description)
      end
    end
  end
end
