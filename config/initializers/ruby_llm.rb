# frozen_string_literal: true

RubyLLM.configure do |config|
  config.logger = Rails.logger
  config.request_timeout = 120
  config.use_new_acts_as = true
  config.model_registry_file = Rails.root.join("config/models.json").to_s
end
