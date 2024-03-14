Rails.application.config.to_prepare do
  Anthropic::Client.class_eval do
    def messages(model:, messages:, system: nil, parameters: {})
      parameters.merge!(system: system) if system
      parameters.merge!(model: model, messages: messages)

      Anthropic::Client.json_post(path: "/messages", parameters: parameters).tap do |response|
        return if response.is_a?(Array) && response == []
        return response if response && response.is_a?(Hash) && response.dig("content", 0, "text").present?

        # handle error response
        error_type = response.dig("error", "type") # overloaded_error api_error rate_limit_error
        error_message = response.dig("error", "message")
        raise Anthropic::Error, "#{error_type}: #{error_message}"
      end
    end
  end
end