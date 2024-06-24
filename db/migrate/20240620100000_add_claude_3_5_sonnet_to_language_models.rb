class AddClaude35SonnetToLanguageModels < ActiveRecord::Migration[7.0]
  def up
    # Insert 'claude-3-5-sonnet-20240620' with position 20
    LanguageModel.create!(
      position: 19,
      name: 'claude-3-5-sonnet-20240620',
      description: 'Claude 3.5 Sonnet (2024-06-20)',
      supports_images: true
    )

    LanguageModel.class_eval do
      def readonly?
        false
      end
    end

    # Increment the position of existing Language Models where position >= 19
    LanguageModel.where('position >= 19').where.not(name: 'claude-3-5-sonnet-20240620').find_each do |model|
      model.update(position: model.position + 1)
    end

    Assistant.where(name: "Claude 3 Opus").update_all(name: "Claude 3.5 Sonnet")
    if language_model_id = LanguageModel.find_by(name: "claude-3-opus-20240229")&.id
      Assistant.where(name: "Claude 3 Sonnet").update_all(name: "Claude 3 Opus", language_model_id: language_model_id)
    end
  end

  def down
    raise "This migration can't be reversed easily."
  end
end
