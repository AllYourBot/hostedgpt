RubyLLM.configure do |config|
  config.openai_api_key = ENV["DEFAULT_OPENAI_KEY"] || "dummy-key-for-test"
  config.anthropic_api_key = ENV["DEFAULT_ANTHROPIC_KEY"] || "dummy-key-for-test"
  config.gemini_api_key = ENV["DEFAULT_GEMINI_KEY"] || "dummy-key-for-test"

  config.logger = Rails.logger
  config.request_timeout = Rails.env.production? ? 120 : 30
  config.log_level = Rails.env.production? ? :info : :debug
end
