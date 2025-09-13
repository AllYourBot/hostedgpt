class AddSupportsPdfToLanguageModels < ActiveRecord::Migration[8.0]
  def change
    add_column :language_models, :supports_pdf, :boolean, default: false, null: false
  end
end
