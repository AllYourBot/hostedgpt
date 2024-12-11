class MoveSystemLanguageModelsToUsers < ActiveRecord::Migration[7.1]
  # 1. Create api_services records (one OpenAI, one Anthropic) for each users record, copying the users' API keys
  # 2. Create copies of system language_models for each users record
  # 3. Link all assistants to the corresponding user's language_model
  # 4. Delete the openai_key and anthropic_key columns from the users table
  # 5. Delete the language_models records that have user_id = NULL
  # 6. Add a constraint to the language_models table that user_id cannot be NULL

  class ::User < ::ApplicationRecord
    encrypts :openai_key, :anthropic_key
  end

  def up
    Rails.logger.info "Create api_services/language_models records for all #{User.count} users records"
    User.all.find_each do |user|
      Rails.logger.info "Create api_services records for OpenAI for user #{user.id}"
      openai_api_service = user.api_services.create!(name: "OpenAI", driver: :openai, url: "https://api.openai.com/v1/", token: user.openai_key)
      Rails.logger.info "Create api_services records for Anthropic for user #{user.id}"
      anthropic_api_service = user.api_services.create!(name: "Anthropic", driver: :anthropic, url: "https://api.anthropic.com/", token: user.anthropic_key)

      LanguageModel.where(user_id: nil).each do |system_language_model|
        Rails.logger.info "`Create copy of language_model record #{system_language_model.api_name} for user #{user.id}"
        user_language_model = user.language_models.create(system_language_model.slice(:api_name, :name, :supports_images, :deleted_at))
        if system_language_model.api_name =~ /^gpt/
          user_language_model.api_service = openai_api_service
        else
          user_language_model.api_service = anthropic_api_service
        end
        user_language_model.save!
        user.assistants_including_deleted.where(language_model_id: system_language_model.id).each do |assistant|
          Rails.logger.info "`Update assistant #{assistant.id} to use user's new language_models record #{user_language_model.id}"
          assistant.update!(language_model: user_language_model)
        end
      end
    end

    remove_column :users, :anthropic_key
    remove_column :users, :openai_key

    LanguageModel.where(user_id: nil).delete_all

    change_column_null :language_models, :user_id, false
  end

  def down
    raise ActiveRecord::IrreversibleMigration.new "Can't determine original data"
  end
end
