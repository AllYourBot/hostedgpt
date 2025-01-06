class AddPricesToLanguageModels < ActiveRecord::Migration[7.1]
  def change
    add_column :language_models, :input_token_cost_cents, :decimal, precision: 30, scale: 15, null: true
    add_column :language_models, :output_token_cost_cents, :decimal, precision: 30, scale: 15, null: true
  end
end
