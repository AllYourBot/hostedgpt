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

  Anthropic::HTTP.class_eval do
    def json_post(path:, parameters:)
      response = conn.post(uri(path: path)) do |req|
        if parameters[:stream].is_a?(Proc)
          req.options.on_data = to_json_stream(user_proc: parameters[:stream])
          parameters[:stream] = true # Necessary to tell Anthropic to stream.
        end

        req.headers = headers
        req.body = parameters.to_json
      end

      error_codes = {
        400 => "invalid_request_error: There was an issue with the format or content of your request.",
        401 => "authentication_error: There's an issue with your API key.",
        403 => "permission_error: Your API key does not have permission to use the specified resource.",
        404 => "not_found_error: The requested resource was not found.",
        429 => "rate_limit_error: Your account has hit a rate limit.",
        500 => "api_error: An unexpected error has occurred internal to Anthropic's systems.",
        529 => "overloaded_error: Anthropic's API is temporarily overloaded."
      }

      if response&.status != 200
        raise StandardError.new("Anthropic #{response&.status} Error - #{error_codes[response&.status]}")
      else
        to_json(response&.body)
      end
    end
  end
end