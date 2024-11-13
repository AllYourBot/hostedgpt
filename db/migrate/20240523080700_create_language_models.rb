class CreateLanguageModels < ActiveRecord::Migration[7.1]
  def up
    create_table :language_models do |t|
      t.integer :position, null: false
      t.string :name, null: false
      t.text :description, null: false
      t.boolean :supports_images, null: false

      t.timestamps
    end

    # Initially supported models
    [
      [1, "gpt-best", "Best OpenAI Model", true],
      [2, "claude-best", "Best Anthropic Model", true],

      [3, "gpt-4o", "GPT-4o (latest)", true],
      [4, "gpt-4o-2024-05-13", "GPT-4o Omni Multimodal (2024-05-13)", true],

      [5, "gpt-4-turbo", "GPT-4 Turbo with Vision (latest)", true],
      [6, "gpt-4-turbo-2024-04-09", "GPT-4 Turbo with Vision (2024-04-09)", true],
      [7, "gpt-4-turbo-preview", "GPT-4 Turbo Preview", false],
      [8, "gpt-4-0125-preview", "GPT-4 Turbo Preview (2024-01-25)", false],
      [9, "gpt-4-1106-preview", "GPT-4 Turbo Preview (2023-11-06)", false],
      [10, "gpt-4-vision-preview", "GPT-4 Turbo with Vision Preview (2023-11-06)", true],
      [11, "gpt-4-1106-vision-preview", "GPT-4 Turbo with Vision Preview (2023-11-06)", true],

      [12, "gpt-4", "GPT-4 (latest)", false],
      [13, "gpt-4-0613", "GPT-4 Snapshot improved function calling (2023-06-13)", false],

      [14, "gpt-3.5-turbo", "GPT-3.5 Turbo (latest)", false],
      [15, "gpt-3.5-turbo-16k-0613", "GPT-3.5 Turbo (2022-06-13)", false],
      [16, "gpt-3.5-turbo-0125", "GPT-3.5 Turbo (2022-01-25)", false],
      [17, "gpt-3.5-turbo-1106", "GPT-3.5 Turbo (2022-11-06)", false],
      [18, "gpt-3.5-turbo-instruct", "GPT-3.5 Turbo Instruct", false],

      [19, "claude-3-opus-20240229", "Claude 3 Opus (2024-02-29)", true],
      [20, "claude-3-sonnet-20240229", "Claude 3 Sonnet (2024-02-29)", true],
      [21, "claude-3-haiku-20240307", "Claude 3 Haiku (2024-03-07)", true],
      [22, "claude-2.1", "Claude 2.1", false],
      [23, "claude-2.0", "Claude 2.0", false],
      [24, "claude-instant-1.2", "Claude Instant 1.2", false]
    ].each do |position, name, description, supports_images|
      create_without_validation!(position: position, name: name, description: description, supports_images: supports_images)
    end

    max_position = 24

    # Respect some users who may have added their own model values in the assistants table
    (Assistant.all.pluck(:model).uniq - LanguageModel.all.pluck(:name)).each do |model_name|
      Rails.logger.info "Create language_models record from assistants column value: #{model_name.inspect}. Setting supports_images to false, update manually if it has support"
      create_without_validation!(name: model_name, description: model_name, position: max_position += 1, supports_images: false)
    end

    add_reference :assistants, :language_model, null: true, foreign_key: { to_table: :language_models}

    Assistant.all.each do |a|
      Rails.logger.info "Have assistant #{a.id} with model #{a.model}"
    end
    ActiveRecord::Base.connection.execute "update assistants a set language_model_id = (select id from language_models lm where lm.name = a.model)"

    remove_column :assistants, :model
    remove_column :assistants, :images
  end

  def down
    add_column  :assistants, :images, :boolean
    add_column :assistants, :model, :string

    ActiveRecord::Base.connection.execute "update assistants a set images = (select supports_images from language_models lm where lm.id=a.language_model_id)"
    ActiveRecord::Base.connection.execute "update assistants a set model = (select name from language_models lm where lm.id=a.language_model_id)"

    remove_column :assistants, :language_model_id
    drop_table :language_models
  end

  def create_without_validation!(attributes)
    LanguageModel.skip_callback(:save, :after, :update_best_language_model_for_api_service)
    begin
      record = LanguageModel.new(attributes)
      if !record.save(validate: false)
        raise "Could not create LanguageModel record for #{attributes.inspect}"
      end
    ensure
      LanguageModel.set_callback(:save, :after, :update_best_language_model_for_api_service)
    end
    record
  end
end
