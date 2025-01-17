class ChangeLanguageModelsCostColumnsDefault < ActiveRecord::Migration[7.2]
  def up
    change_column_default :language_models, :input_token_cost_cents, 0
    change_column_default :language_models, :output_token_cost_cents, 0
  end

  # change_column_default doesn't know the original default, which actually was no-default
  def down
    change_column_default :language_models, :input_token_cost_cents, nil
    change_column_default :language_models, :output_token_cost_cents, nil
  end

end
