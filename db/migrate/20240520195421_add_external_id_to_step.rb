class AddExternalIdToStep < ActiveRecord::Migration[7.1]
  def up
    add_column :steps, :external_id, :text, comment: "The Backend AI system (e.g OpenAI) Step Id"
  end
  def down
    remove_column :steps, :external_id, :text
  end
end
