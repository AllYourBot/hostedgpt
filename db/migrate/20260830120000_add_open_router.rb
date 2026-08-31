class AddOpenRouter < ActiveRecord::Migration[8.1]
  def up
    # The model import matches services by name ("OpenRouter"), and dispatch
    # matches on the driver and URL pair. A user who pre-connected OpenRouter
    # through the settings UI may have named their service anything, so an
    # existing openai-driver row at OpenRouter's URL is adopted and renamed;
    # the user's token is untouched. Services with other drivers at that URL
    # are left alone and a canonical row is created alongside them.
    User.all.find_each do |user|
      existing = user.api_services.find_by(url: APIService::URL_OPENROUTER, driver: :openai)
      if existing
        existing.update!(name: "OpenRouter") unless existing.name == "OpenRouter"
      else
        user.api_services.create!(url: APIService::URL_OPENROUTER, driver: :openai, name: "OpenRouter")
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
