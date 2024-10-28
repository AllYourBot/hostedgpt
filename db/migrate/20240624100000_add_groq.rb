class AddGroq < ActiveRecord::Migration[7.0]
  def up
    # The schema for this table has changed too much, need this when migrating the db from scratch
    Assistant.reset_column_information
    LanguageModel.reset_column_information
    APIService.reset_column_information

    User.all.find_each do |user|
      groq_api_service = user.api_services.create!(url: APIService::URL_GROQ, driver: :openai, name: "Groq")
      language_model = user.language_models.create!(position: 3, api_name: LanguageModel::BEST_GROQ, api_service: groq_api_service, name: "Best Open-Source Model", supports_images: false)
      user.language_models.where("position >= 3").where.not(id: language_model.id).find_each do |model|
        model.update(position: model.position + 1)
      end

      [
        ["llama3-70b-8192", "Meta Llama 3 70b", false, groq_api_service],
        ["llama3-8b-8192", "Meta Llama 3 8b", false, groq_api_service],
        ["mixtral-8x7b-32768", "Mistral 8 7b", false, groq_api_service],
        ["gemma-7b-it", "Google Gemma 7b", false, groq_api_service],
      ].each do |api_name, name, supports_images, api_service|
        user.language_models.create!(api_name: api_name, api_service: api_service, name: name, supports_images: supports_images)
      end

      [ "GPT-3.5", "Claude 3 Opus" ].each do |name|
        asst = user.assistants.find_by(name: name)
        next if asst.nil?
        asst.deleted! if asst.conversations.count == 0
        asst.deleted! if asst.conversations.count == 1 && asst.conversations.first.messages.count <= 2
      end

      user.assistants.create!(name: "Meta Llama 3 70b", language_model: language_model)
    end
  end

  def down
    raise "This migration can't be reversed easily."
  end
end
