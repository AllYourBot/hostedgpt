class ChatCompletionAPI

  # This is a lightweight wrapper around the OpenAI::Client gem that hides away a bunch of the complexity.
  #
  # ChatCompletionAPI.get_next_response("You are a comedian", ["Tell me a joke"], model: "gpt-4")
  #

  def self.get_next_response(system_message, chat_messages, params = {})
    # docs for this format:  https://platform.openai.com/docs/api-reference/chat

    message_payload = [{
      role: 'system',
      content: system_message
    }]

    chat_messages.each_with_index do |msg, i|
      role = (i % 2 == 0) ? 'user' : 'assistant'

      message_payload << {
        role: role,
        content: msg
      }
    end

    response = call_api({messages: message_payload}.merge(params))
  end


  private

  def self.default_params
    {
      model: "gpt-3.5-turbo-1106",
      max_tokens: 500,                      # a sensible default
      n: 1,
      response_format: { "type": "text" },  # or json_object
    }
  end

  def self.call_api(params)
    params = default_params.deep_symbolize_keys.merge(params.symbolize_keys)

    verify_params!(params)
    verify_token_count!(params)

    response = formatted_api_response(params)

    if params[:response_format]&.dig(:type) == "json_object"
      JSON.parse(response)
    else
      response
    end
  end

  def self.formatted_api_response(params)
    if Rails.env.test?
      raise "In your test you need to wrap with: ChatCompletionAPI.stub :formatted_api_response, 'value' do; end"
    end

    client = OpenAI::Client.new(
      access_token: Current.user.openai_key,
      request_timeout: 240,
    )

    # We are streaming the response even though we queue it all up before returning because this avoids some timeouts with the
    # OpenAI API. If we disable streaming, then requests with really long system prompts and messages struggle to return the
    # full response before OpenAI kills it.

    response = ""

    client.chat(parameters: params.merge(stream: proc { |chunk, _bytesize|
      finished_reason = chunk&.dig("choices", 0, "finish_reason")

      if !finished_reason
        response += chunk&.dig("choices", 0, "delta", "content")&.to_s
      else
        raise finished_reason  unless finished_reason == "stop"
      end
    }))

    response
  end

  def self.verify_params!(params)
    if response_format = params[:response_format]
      if !response_format.is_a?(Hash) || !response_format.dig(:type)&.in?(%w{ json_object text })
        raise "Your response_format is invalid. e.g. response_format: { 'type': 'json_object' }"
      end
    end
  end

  def self.verify_token_count!(params)
    count = token_count(params[:messages].to_json, model: params[:model]) + params[:max_tokens]
    limit = model_token_limit(params[:model])

    if count >= limit
      raise "Too many tokens. Using #{count} tokens (with #{params[:max_tokens]} of those being in the response), but the model #{params[:model]} has a limit of #{limit} tokens."
    end
  end

  def self.token_count(string, model: nil)
    tokenize(string, model: model).length
  end

  def self.tokenize(string, model: nil)
    encoding = Tiktoken.encoding_for_model(model)
    encoding.encode(string)
  end

  def self.model_token_limit(name)
    # Docs for available models:  https://platform.openai.com/docs/models/gpt-4-and-gpt-4-turbo

    {
      'gpt-4-turbo-2024-04-09' => 128000,
      'gpt-4-0125-preview' => 128000,
      'gpt-4-1106-preview' => 128000,
      'gpt-4-vision-preview' => 128000,
      'gpt-4-1106-vision-preview' => 128000,
      'gpt-4' => 8192,
      'gpt-4-32k' => 32768,
      'gpt-4-0613' => 8192,
      'gpt-4-32k-0613' => 32768,
      'gpt-3.5-turbo-0125' => 16385,
      'gpt-3.5-turbo-1106' => 16385,
      'gpt-3.5-turbo' => 4096,
      'gpt-3.5-turbo-16k' => 16385,
      'gpt-3.5-turbo-instruct' => 4096
    }[name]
  end
end