class AddIndexAndVersionToMessages < ActiveRecord::Migration[7.1]
  def up
    add_column :messages, :index, :integer
    add_column :messages, :version, :integer

    Conversation.all.find_each do |conversation|
      conversation.messages.order(:created_at).each_with_index do |message, index|
        message.update(index: index, version: 1)
      end
    end

    change_column :messages, :index, :integer, null: false
    change_column :messages, :version, :integer, null: false

    add_index :messages, :index
    add_index :messages, :version
  end

  def down
    remove_column :messages, :index
    remove_column :messages, :version
  end
end