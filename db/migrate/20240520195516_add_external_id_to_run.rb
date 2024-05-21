class AddExternalIdToRun < ActiveRecord::Migration[7.1]
  def up
    add_column :runs, :external_id, :text, if_not_exists: true,  comment: "The Backend AI system (e.g OpenAI) Run Id"
  end
  def down
    remove_column :runs, :external_id, :text
  end
end
