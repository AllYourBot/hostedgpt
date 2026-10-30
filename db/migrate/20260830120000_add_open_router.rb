class AddOpenRouter < ActiveRecord::Migration[8.1]
  class User < ActiveRecord::Base
    self.table_name = "users"
  end

  class APIService < ActiveRecord::Base
    self.table_name = "api_services"

    # Only persisted once the column exists, so this also runs against today's schema.
    attribute :service_type, :string, default: "AI"
  end

  URL_OPENROUTER = "https://openrouter.ai/api/v1/"

  def up
    # The model import matches services by name ("OpenRouter"), and dispatch
    # matches on the driver and URL pair. A user who pre-connected OpenRouter
    # through the settings UI may have named their service anything, so an
    # existing openai-driver row at OpenRouter's URL is adopted and renamed;
    # the user's token is untouched. Services with other drivers at that URL
    # are left alone and a canonical row is created alongside them.
    User.ids.each do |user_id|
      existing = APIService.find_by(user_id:, url: URL_OPENROUTER, driver: "openai")
      if existing
        existing.update!(name: "OpenRouter") unless existing.name == "OpenRouter"
      else
        APIService.create!(user_id:, url: URL_OPENROUTER, driver: "openai", name: "OpenRouter")
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
