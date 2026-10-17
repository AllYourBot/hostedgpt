RubyLLM.configure do |config|
  config.openai_api_key = ENV["DEFAULT_OPENAI_KEY"] || "dummy-key-for-test"
  config.anthropic_api_key = ENV["DEFAULT_ANTHROPIC_KEY"] || "dummy-key-for-test"
  config.gemini_api_key = ENV["DEFAULT_GEMINI_KEY"] || "dummy-key-for-test"
  # RubyLLM 2.0 defaults OpenAI traffic to the Responses API. HostedGPT's
  # streaming chunk shape, tool-call payloads, and replay hashes are pinned to
  # Chat Completions (which Groq and OpenRouter also ride); switching protocols
  # is a separate post-cleanup evaluation.
  config.openai_protocol = :chat_completions
  config.logger = Rails.logger
  config.request_timeout = Rails.env.production? ? 120 : 30
end
