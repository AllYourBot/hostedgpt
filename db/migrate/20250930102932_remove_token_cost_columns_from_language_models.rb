class RemoveTokenCostColumnsFromLanguageModels < ActiveRecord::Migration[8.0]
  def change
    remove_column :language_models, :input_token_cost_cents, :decimal
    remove_column :language_models, :output_token_cost_cents, :decimal
  end
end
