class PopulateDocumentsAssistantId < ActiveRecord::Migration[7.1]
  def up
    ActiveRecord::Base.connection.execute "update documents docs set assistant_id = (select assistant_id from messages msgs where msgs.id = docs.message_id) where docs.assistant_id is null"
  end

  def down
    say "No change"
  end
end
