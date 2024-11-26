class AddSlugToAssistants < ActiveRecord::Migration[7.2]
  def change
    add_column :assistants, :slug, :string, null: true
    add_index :assistants, [:user_id, :slug], unique: true, where: "slug IS NOT NULL"

    # Update User's assistants to use the default slugs in assistants.yml
    User.find_each do |user|
      gpt4o = LanguageModel.find_by(api_name: "gpt-4o")
      gpt4o_mini = LanguageModel.find_by(api_name: "gpt-4o-mini")
      claude_3_5_sonnet_20241022 = LanguageModel.find_by(api_name: "claude-3-5-sonnet-20241022")
      claude_3_5_sonnet_20240620 = LanguageModel.find_by(api_name: "claude-3-5-sonnet-20240620")
      llama_3_1_70b = LanguageModel.find_by(api_name: "llama-3.1-70b")
      llama_3_70b = LanguageModel.find_by(api_name: "llama3-70b-8192")

      if gpt4o && (assistant = user.assistants.find_by(language_model: gpt4o))
        assistant.update(slug: "gpt-4o")
      end
      if gpt4o_mini && (assistant = user.assistants.find_by(language_model: gpt4o_mini))
        assistant.update(slug: "gpt-4o-mini")
      end

      if claude_3_5_sonnet_20241022 && (assistant = user.assistants.find_by(language_model: claude_3_5_sonnet_20241022))
        assistant.update(slug: "claude-sonnet")
      elsif claude_3_5_sonnet_20240620 && (assistant = user.assistants.find_by(language_model: claude_3_5_sonnet_20240620))
        assistant.update(slug: "claude-sonnet")
      end

      if llama_3_1_70b && (assistant = user.assistants.find_by(language_model: llama_3_1_70b))
        assistant.update(slug: "llama-3-70b")
      elsif llama_3_70b && (assistant = user.assistants.find_by(language_model: llama_3_70b))
        assistant.update(slug: "llama-3-70b")
      end
    end
  end
end
