class ExpandLanguageModels < ActiveRecord::Migration[7.1]
  def change
    add_column :language_models, :deleted_at, :timestamp, default: nil

    rename_column :language_models, :name, :api_name
    change_column_comment :language_models, :api_name, "This is the name that API calls are expecting."
    rename_column :language_models, :description, :name

    add_reference :language_models, :user, null: true, foreign_key: true, index: true
    add_index :language_models, [:user_id, :deleted_at]
  end
end
