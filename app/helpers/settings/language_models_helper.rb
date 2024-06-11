module Settings
  module LanguageModelsHelper
    def display_boolean(value)
      ActiveModel::Type::Boolean.new.cast(value) ? 'Yes' : 'No'
    end

    def language_model_edit_show_path(language_model)
      if language_model.created_by_current_user?
        edit_settings_language_model_path(language_model)
      else
        settings_language_model_path(language_model)
      end
    end
  end
end
