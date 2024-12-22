class AddBestToLanguageModels < ActiveRecord::Migration[7.2]
  def change
    add_column :language_models, :best, :boolean, default: false
  end
end
