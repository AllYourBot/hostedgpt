class AddPricesToLanguageModels < ActiveRecord::Migration[7.1]
  def change
    add_column :language_models, :input_token_cost_per_million, :decimal, precision: 10, scale: 2, default: 0.0, null: true
    add_column :language_models, :output_token_cost_per_million, :decimal, precision: 10, scale: 2, default: 0.0, null: true
  end
end
