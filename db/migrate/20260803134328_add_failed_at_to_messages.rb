class AddFailedAtToMessages < ActiveRecord::Migration[8.1]
  def change
    add_column :messages, :failed_at, :datetime
  end
end
