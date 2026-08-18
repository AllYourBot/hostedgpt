class AIBackend::RubyLLM < AIBackend
  class ConfigurationError < StandardError; end
  class RateLimitError < StandardError; end

  def self.supports_driver?(_driver)
    false
  end

  def self.client
    Rails.env.test? ? ::TestClient::RubyLLM : ::RubyLLM
  end

  def get_oneoff_message(*)
    raise NotImplementedError
  end

  def stream_next_conversation_message(*)
    raise NotImplementedError
  end

  def self.test_execute(*)
    raise NotImplementedError
  end

  private

  def client_method_name
    raise NotImplementedError
  end

  def configuration_error
    raise NotImplementedError
  end

  def set_client_config(*)
    raise NotImplementedError
  end

  def preceding_messages(*)
    raise NotImplementedError
  end

  def preceding_conversation_messages
    raise NotImplementedError
  end

  def stream_handler(*)
    raise NotImplementedError
  end

  def format_parallel_tool_calls(*)
    raise NotImplementedError
  end
end
