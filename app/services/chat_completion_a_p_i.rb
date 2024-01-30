class ChatCompletionAPI

  # This is a lightweight wrapper around the OpenAI::Client gem that hides away a bunch of the complexity.
  #
  # ChatCompletionAPI.get_next_response("You are a comedian", ["Tell me a joke"], model: "gpt-4")
  #

  def self.api_key
    Current.user.openai_key
  end

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

    client = OpenAI::Client.new(
      access_token: api_key,
      request_timeout: 240,
    )

    response = ""
    retries = 0
    keep_retrying = true

    begin
      verify_token_count!(params)
      response = ""
      finished_reason = nil

      if Rails.env.test?
        response = formatted_api_response
      else
        client.chat(parameters: params.merge(stream: proc { |chunk, _bytesize|
          finished_reason = chunk&.dig("choices", 0, "finish_reason")

          if !finished_reason
            response += chunk&.dig("choices", 0, "delta", "content")&.to_s
          else
            raise finished_reason  unless finished_reason == "stop"
          end
        }))
      end
    rescue => e
      if retries < 2 && e.class == nil # this was RestClient::Exceptions::ReadTimeout but I need to see what gets thrown now that the library switched to HTTParty and then update this
        retries = retries + 1
        sleep (1*retries)
        retry
      elsif retries < 2 && e.message == 'length' && (content = params[:messages].last[:content]).length > 100000
        retries = retries + 1
        sleep (1*retries)

        params[:messages][-1][:content] = content[0...50000] + "\n...\n" + content[-50000...]
        retry
      elsif !e.message.include?('stubs')
        puts "Error: retried #{retries} times. Error: #{e}"
        #binding.pry  unless e.message == 'length'
        sleep 2
        retry  if keep_retrying
      end

      raise e
    end

    if params[:response_format]&.dig(:type) == "json_object"
      JSON.parse(response)
    else
      response
    end
  end

  def self.formatted_api_response
    raise "In your test you need to add: ChatCompletionAPI.stubs(:formatted_api_response).returns(...)"
  end


  private

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
      'gpt-4-0125-preview': 128000,
      'gpt-4-1106-preview': 128000,
      'gpt-4-vision-preview': 128000,
      'gpt-4': 8192,
      'gpt-4-32k': 32768,
      'gpt-4-0613': 8192,
      'gpt-4-32k-0613': 32768,
      'gpt-3.5-turbo-1106': 16385,
      'gpt-3.5-turbo': 4096,
      'gpt-3.5-turbo-16k': 16385,
      'gpt-3.5-turbo-instruct': 4096
    }[name.to_sym]
  end
end