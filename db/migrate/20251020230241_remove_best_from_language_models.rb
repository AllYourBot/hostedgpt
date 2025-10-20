class RemoveBestFromLanguageModels < ActiveRecord::Migration[8.0]
  def change
    remove_column :language_models, :best, :boolean
  end
end
