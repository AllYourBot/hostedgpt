class AddCheaperInference < ActiveRecord::Migration[8.1]
  def up
    # Same approach as AddOpenRouter: the model import matches services by
    # name ("Cheaper Inference"), and dispatch matches on the driver and URL
    # pair. An existing openai-driver row at Cheaper Inference's URL is adopted
    # and renamed; the user's token is untouched. Services with other drivers
    # at that URL are left alone and a canonical row is created alongside them.
    User.all.find_each do |user|
      existing = user.api_services.find_by(url: APIService::URL_CHEAPER_INFERENCE, driver: :openai)
      if existing
        existing.update!(name: "Cheaper Inference") unless existing.name == "Cheaper Inference"
      else
        user.api_services.create!(url: APIService::URL_CHEAPER_INFERENCE, driver: :openai, name: "Cheaper Inference")
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
