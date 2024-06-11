class AddAPIServiceReferenceToLanguageModels < ActiveRecord::Migration[7.1]
  def change
    add_reference :language_models, :api_service, null: true, foreign_key: true, index: true
  end
end
