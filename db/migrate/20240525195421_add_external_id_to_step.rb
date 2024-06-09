class AddExternalIdToStep < ActiveRecord::Migration[7.1]
  def up
    add_column :steps, :external_id, :text, if_not_exists: true, comment: "The Backend AI system (e.g OpenAI) Step Id"
  end
  def down
    remove_column :steps, :external_id, :text
  end
end
