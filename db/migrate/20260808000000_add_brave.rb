class AddBrave < ActiveRecord::Migration[8.1]
  class User < ActiveRecord::Base
    self.table_name = "users"
  end

  class APIService < ActiveRecord::Base
    self.table_name = "api_services"
  end

  URL_BRAVE = "https://api.search.brave.com/res/v1/"

  def up
    User.ids.each do |user_id|
      APIService.create!(user_id:, url: URL_BRAVE, driver: "brave", name: "Brave")
    end
  end

  def down
    APIService.where(url: URL_BRAVE, driver: "brave").delete_all
  end
end
