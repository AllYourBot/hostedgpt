class AddGroq < ActiveRecord::Migration[7.0]
  def up
    # The schema for this table has changed too much, need this when migrating the db from scratch
    Assistant.reset_column_information
    LanguageModel.reset_column_information
    APIService.reset_column_information

    User.all.find_each do |user|
      user.api_services.create!(url: APIService::URL_GROQ, driver: :openai, name: "Groq")
    end
  end

  def down
    raise "This migration can't be reversed easily."
  end
end
