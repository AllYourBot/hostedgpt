class CreateLanguageModels < ActiveRecord::Migration[7.1]
  def up
    create_table :language_models do |t|
      t.string :name
      t.text :description

      t.timestamps
    end

    # Initially supported models
    [
      [1, 'gpt-best', 'Best OpenAI Model'],
      [2, 'claude-best', 'Best Anthropic Model'],

      [3, 'gpt-4', 'ChatGPT 4'],
      [4, 'gpt-4-turbo', 'ChatGPT 4 Turbo with Vision (may update in future)'],
      [5, 'gpt-4-turbo-2024-04-09', 'ChatGPT-4 Turbo with Vision (2024-04-09)'],
      [6, 'gpt-4-turbo-preview', 'ChatGPT 4 Turbo Preview'],
      [7, 'gpt-4-0125-preview', 'ChatGPT 4 Turbo Preview (2024-01-25)'],
      [8, 'gpt-4-1106-preview', 'ChatGPT 4 Turbo Preview (2023-11-06)'],
      [9, 'gpt-4-vision-preview', 'ChatGPT 4 Turbo Model preview with the ability to understand images (2023-11-06)'],
      [10, 'gpt-4-1106-vision-preview', 'ChatGPT 4 Turbo preview with the ability to understand images (2023-11-06)'],
      [11, 'gpt-4-0613', 'ChatGPT 4 Snapshot improved function calling (2023-06-13)'],

      [12, 'gpt-3.5-turbo', 'ChatGPT 3.5 Turbo'],
      [13, 'gpt-3.5-turbo-16k-0613', 'ChatGPT 3.5 Turbo (2022-06-13)'],
      [14, 'gpt-3.5-turbo-0125', 'ChatGPT 3.5 Turbo (2022-01-25)'],
      [15, 'gpt-3.5-turbo-1106', 'ChatGPT 3.5 Turbo (2022-11-06)'],
      [16, 'gpt-3.5-turbo-instruct', 'ChatGPT 3.5 Turbo Instruct'],

      [17, 'claude-3-opus-20240229', 'Claude 3 Opus (2024-02-29)'],
      [18, 'claude-3-sonnet-20240229', 'Claude 3 Sonnet (2024-02-29)'],
      [19, 'claude-3-haiku-20240307', 'Claude 3 Haiku (2024-03-07)'],
      [20, 'claude-2.1', 'Claude 2.1'],
      [21, 'claude-2.0', 'Claude 2.0'],
      [22, 'claude-instant-1.2', 'Claude Instant 1.2']
    ].each do |db_id, name, description|
      record = LanguageModel.new(name: name, description: description)
      record.id = db_id
      record.save!
    end

    ActiveRecord::Base.connection.execute "ALTER SEQUENCE language_models_id_seq RESTART WITH 30;"

    # Respect some users who may have added their own model values in the assistants table
    (Assistant.all.pluck(:model).uniq - LanguageModel.all.pluck(:name)).each do |model_name|
      Rails.logger.info "Create language_models record from assistants column value: #{model_name.inspect}"
      LanguageModel.create!(name: model_name, description: model_name)
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
