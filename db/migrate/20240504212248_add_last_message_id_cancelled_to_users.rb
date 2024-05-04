class AddLastMessageIdCancelledToUsers < ActiveRecord::Migration[7.1]
  def change
    add_reference :users, :last_cancelled_message, null: true, foreign_key: { to_table: :messages }
  end
end
