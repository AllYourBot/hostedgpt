class AddGemini < ActiveRecord::Migration[7.2]
  def up
    User.all.find_each do |user|
      gemini_api_service = user.api_services.create!(url: APIService::URL_GEMINI, driver: :gemini, name: "Google Gemini")

      language_model = user.language_models.create!(
        api_name: "gemini-1.5-pro-002",
        name: "Gemini Pro 1.5",
        api_service: gemini_api_service,
        supports_images: true
      )

      user.assistants.create!(
        name: "Gemini Pro 1.5",
        slug: "gemini-1.5-pro-002",
        language_model: language_model
      )
    end
  end

  def down
    raise "This migration can't be reversed easily."
  end
end
