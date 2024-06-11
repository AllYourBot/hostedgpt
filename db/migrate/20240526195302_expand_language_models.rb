class ExpandLanguageModels < ActiveRecord::Migration[7.1]
  def change
    add_column :language_models, :user_id, :bigint, null: true
    add_column :language_models, :deleted_at, :timestamp, default: nil

    add_index :language_models, [:user_id, :deleted_at]
  end
end
