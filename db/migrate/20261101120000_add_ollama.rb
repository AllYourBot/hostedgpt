class AddOllama < ActiveRecord::Migration[8.1]
  class User < ActiveRecord::Base
    self.table_name = "users"
  end

  class APIService < ActiveRecord::Base
    self.table_name = "api_services"

    attribute :service_type, :string, default: "AI"
  end

  URL_OLLAMA = "http://localhost:11434/v1/"

  def up
    # The model and assistant imports match the service by name ("Ollama").
    # A user who already connected a local Ollama through the settings UI
    # keeps their row and token; it is only renamed.
    User.ids.each do |user_id|
      existing = APIService.find_by(user_id:, url: URL_OLLAMA, driver: "openai")
      if existing
        existing.update!(name: "Ollama") unless existing.name == "Ollama"
      else
        APIService.create!(user_id:, url: URL_OLLAMA, driver: "openai", name: "Ollama")
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
