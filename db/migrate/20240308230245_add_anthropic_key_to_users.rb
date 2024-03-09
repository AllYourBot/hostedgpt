class AddAnthropicKeyToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :anthropic_key, :string
  end
end
