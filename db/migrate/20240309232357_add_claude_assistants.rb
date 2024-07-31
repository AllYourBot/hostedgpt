class AddClaudeAssistants < ActiveRecord::Migration[7.1]
  def up
    User.all.each do |user|
      user.assistants.create! name: "Claude 3 Opus", model: "claude-3-opus-20240229", images: true
      user.assistants.create! name: "Claude 3 Sonnet", model: "claude-3-sonnet-20240229", images: true
    end
  end

  def down
    Assistant.name_like("Claude").destroy_all
  end
end
