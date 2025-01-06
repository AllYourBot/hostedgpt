class AddV1ToAPIServicesURL < ActiveRecord::Migration[7.2]
  def up
    APIService.where(url: "https://api.openai.com/").each do |api_service|
      api_service.update(url: api_service.url+"v1/")
    end
  end
  def down
    APIService.where(url: "https://api.openai.com/v1/").each do |api_service|
      api_service.update(url: api_service.url.gsub("v1/",""))
    end
  end
end