class AddBrave < ActiveRecord::Migration[8.1]
  def up
    User.all.find_each do |user|
      user.api_services.create!(url: APIService::URL_BRAVE, driver: :brave, name: "Brave")
    end
  end

  def down
    APIService.where(url: APIService::URL_BRAVE, driver: :brave).destroy_all
  end
end
