class AddSupportsToolsToLanguageModels < ActiveRecord::Migration[7.1]
  def change
    add_column :language_models, :supports_tools, :boolean, default: true
  end
end
