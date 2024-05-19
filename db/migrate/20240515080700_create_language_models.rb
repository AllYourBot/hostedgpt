class CreateLanguageModels < ActiveRecord::Migration[7.1]
  def up
    create_table :language_models do |t|
      t.integer :position
      t.string :name
      t.text :description

      t.timestamps
    end

    # Initially supported models
    [
      [1, 'gpt-best', 'Best OpenAI Model'],
      [2, 'claude-best', 'Best Anthropic Model'],

      [3, 'gpt-4o', 'GPT-4o (latest)'],
      [4, 'gpt-4o-2024-05-13', 'GPT-4o Omni Multimodal (2024-05-13)'],

      [5, 'gpt-4-turbo', 'GPT-4 Turbo with Vision (latest)'],
      [6, 'gpt-4-turbo-2024-04-09', 'GPT-4 Turbo with Vision (2024-04-09)'],
      [7, 'gpt-4-turbo-preview', 'GPT-4 Turbo Preview'],
      [8, 'gpt-4-0125-preview', 'GPT-4 Turbo Preview (2024-01-25)'],
      [9, 'gpt-4-1106-preview', 'GPT-4 Turbo Preview (2023-11-06)'],
      [10, 'gpt-4-vision-preview', 'GPT-4 Turbo with Vision Preview (2023-11-06)'],
      [11, 'gpt-4-1106-vision-preview', 'GPT-4 Turbo with Vision Preview (2023-11-06)'],

      [12, 'gpt-4', 'GPT-4 (latest)'],
      [13, 'gpt-4-0613', 'GPT-4 Snapshot improved function calling (2023-06-13)'],

      [14, 'gpt-3.5-turbo', 'GPT-3.5 Turbo (latest)'],
      [15, 'gpt-3.5-turbo-16k-0613', 'GPT-3.5 Turbo (2022-06-13)'],
      [16, 'gpt-3.5-turbo-0125', 'GPT-3.5 Turbo (2022-01-25)'],
      [17, 'gpt-3.5-turbo-1106', 'GPT-3.5 Turbo (2022-11-06)'],
      [18, 'gpt-3.5-turbo-instruct', 'GPT-3.5 Turbo Instruct'],

      [19, 'claude-3-opus-20240229', 'Claude 3 Opus (2024-02-29)'],
      [20, 'claude-3-sonnet-20240229', 'Claude 3 Sonnet (2024-02-29)'],
      [21, 'claude-3-haiku-20240307', 'Claude 3 Haiku (2024-03-07)'],
      [22, 'claude-2.1', 'Claude 2.1'],
      [23, 'claude-2.0', 'Claude 2.0'],
      [24, 'claude-instant-1.2', 'Claude Instant 1.2']
    ].each do |position, name, description|
      LanguageModel.create!(position: position, name: name, description: description)
    end

    max_position = 24

    # Respect some users who may have added their own model values in the assistants table
    (Assistant.all.pluck(:model).uniq - LanguageModel.all.pluck(:name)).each do |model_name|
      Rails.logger.info "Create language_models record from assistants column value: #{model_name.inspect}"
      LanguageModel.create!(name: model_name, description: model_name, position: max_position += 1)
    end

    add_reference :assistants, :language_model, null: true, foreign_key: { to_table: :language_models}

    Assistant.all.each do |a|
      Rails.logger.info "Have assistant #{a.id} with model #{a.model}"
    end
    ActiveRecord::Base.connection.execute "update assistants a set language_model_id = (select id from language_models lm where lm.name = a.model)"

    remove_column :assistants, :model
  end

  def down
    add_column :assistants, :model, :string
    ActiveRecord::Base.connection.execute "update assistants a set model = (select name from language_models lm where lm.id=a.language_model_id)"

    remove_column :assistants, :language_model_id
    drop_table :language_models
  end
end
