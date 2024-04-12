class NewOpenaiModel < ActiveRecord::Migration[7.1]
  def up
    Assistant.where(model: "gpt-4-vision-preview").update_all(model: "gpt-4-turbo-2024-04-09")
  end

  def down
    Assistant.where(model: "gpt-4-turbo-2024-04-09").update_all(model: "gpt-4-vision-preview")
  end
end
