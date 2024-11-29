class AddGemini < ActiveRecord::Migration[7.2]
  def up
    User.all.find_each do |user|
      user.api_services.create!(url: APIService::URL_GEMINI, driver: :gemini, name: "Google Gemini")
    end
  end

  def down
    APIService.where(url: APIService::URL_GEMINI, driver: :gemini).destroy_all
  end
end
