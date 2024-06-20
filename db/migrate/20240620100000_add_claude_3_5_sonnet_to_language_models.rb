class AddClaude35SonnetToLanguageModels < ActiveRecord::Migration[7.0]
  def change
    # Insert 'claude-3-5-sonnet-20240620' with position 20
    LanguageModel.create!(
      position: 19,
      name: 'claude-3-5-sonnet-20240620',
      description: 'Claude 3.5 Sonnet (2024-06-20)',
      supports_images: true
    )

    # Increment the position of existing Language Models where position >= 19
    LanguageModel.where('position >= 19').where.not(name: 'claude-3-5-sonnet-20240620').find_each do |model|
      model.update(position: model.position + 1)
    end
  end
end
