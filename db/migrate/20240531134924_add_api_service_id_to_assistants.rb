class AddAPIServiceIdToAssistants < ActiveRecord::Migration[7.1]
  def change
    add_column :assistants, :api_service_id, :bigint, null: true
  end
end
