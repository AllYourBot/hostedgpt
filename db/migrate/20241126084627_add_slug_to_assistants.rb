class AddSlugToAssistants < ActiveRecord::Migration[7.2]
  def up
    add_column :assistants, :slug, :string, null: true
    add_index :assistants, [:user_id, :slug], unique: true, where: "slug IS NOT NULL"

    # Update User's assistants to use the default slugs in assistants.yml
    User.find_each do |user|
      language_models = user.language_models
      gpt4o = language_models.find_by(api_name: "gpt-4o")
      gpt4o_mini = language_models.find_by(api_name: "gpt-4o-mini")
      claude_3_5_sonnet_20241022 = language_models.find_by(api_name: "claude-3-5-sonnet-20241022")
      claude_3_5_sonnet_20240620 = language_models.find_by(api_name: "claude-3-5-sonnet-20240620")
      llama_3_1_70b = language_models.find_by(api_name: "llama-3.1-70b-versatile")
      llama_3_70b = language_models.find_by(api_name: "llama3-70b-8192")

      ordered_assistants = user.assistants.order(created_at: :asc)
      if gpt4o && (assistant = ordered_assistants.find_by(language_model: gpt4o))
        assistant.update(slug: "gpt-4o")
      end
      if gpt4o_mini && (assistant = ordered_assistants.find_by(language_model: gpt4o_mini))
        assistant.update(slug: "gpt-4o-mini")
      end

      if claude_3_5_sonnet_20241022 && (assistant = ordered_assistants.find_by(language_model: claude_3_5_sonnet_20241022))
        assistant.update(slug: "claude-sonnet")
      elsif claude_3_5_sonnet_20240620 && (assistant = ordered_assistants.find_by(language_model: claude_3_5_sonnet_20240620))
        assistant.update(slug: "claude-sonnet")
      end

      if llama_3_1_70b && (assistant = ordered_assistants.find_by(language_model: llama_3_1_70b))
        assistant.update(slug: "llama-3-70b")
      elsif llama_3_70b && (assistant = ordered_assistants.find_by(language_model: llama_3_70b))
        assistant.update(slug: "llama-3-70b")
      end

      user.assistants.where(slug: nil).find_each(&:save!)
    end
  end

  def down
    remove_column :assistants, :slug
  end
end
