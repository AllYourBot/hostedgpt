module Settings
  module LanguageModelsHelper
    def display_boolean(value)
      ActiveModel::Type::Boolean.new.cast(value) ? "Yes" : "No"
    end
  end
end
