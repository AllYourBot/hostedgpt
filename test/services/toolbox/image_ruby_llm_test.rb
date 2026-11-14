require "test_helper"

class Toolbox::ImageRubyLLMTest < ActiveSupport::TestCase
  setup do
    @tool = Toolbox::Image.new
    @prompt = "A cartoon image of a cat"
  end

  teardown do
    TestClient::RubyLLM::ContextDouble.reset_recordings!
  end

  test "generate_an_image paints through RubyLLM with the user's OpenAI key" do
    Current.set(user: users(:keith), message: messages(:image_generation_tool_call)) do
      result = @tool.generate_an_image(image_generation_prompt_s: @prompt)

      recorded = TestClient::RubyLLM::ContextDouble.last_paint_call
      assert_equal @prompt, recorded[:prompt], "The prompt should be passed to paint unchanged"
      assert_equal "abc-secret", recorded[:openai_api_key], "Paint should use the user's OpenAI key"
      assert_nil recorded[:gemini_api_key], "OpenAI should win when the user also has a Gemini service"
      assert_equal AIBackend::RubyLLM::IMAGE_MODEL, recorded[:kwargs][:model], "Paint should use the RubyLLM image model"
      assert_equal :openai, recorded[:kwargs][:provider], "Paint should target the OpenAI provider"
      assert_equal "1024x1024", recorded[:kwargs][:size], "Paint should request a square image"
      assert_equal({ quality: "high" }, recorded[:kwargs][:provider_options], "Paint should ask OpenAI for a high quality image")

      assert_equal @prompt, result[:prompt_given], "The tool result should echo the prompt"
      assert_equal "RUBYLLM_BASE64_IMAGE_DATA", result[:json_of_generated_image], "The painted image data should come back to the job"
      assert_includes result[:note_to_assistant], "image", "The note should tell the assistant about the image"
      assert_equal "Image created by tool using OpenAI model #{AIBackend::RubyLLM::IMAGE_MODEL}", result[:message_to_user], "The user should see which model made the image"
    end
  end

  test "an Anthropic assistant still generates the image through the user's OpenAI service" do
    anthropic_message = messages(:image_generation_tool_call).dup
    anthropic_message.assistant = assistants(:keith_claude3)

    Current.set(user: users(:keith), message: anthropic_message) do
      result = @tool.generate_an_image(image_generation_prompt_s: @prompt)

      assert_equal "RUBYLLM_BASE64_IMAGE_DATA", result[:json_of_generated_image], "The painted image data should come back to the job"
      assert_equal "Image created by tool using OpenAI model #{AIBackend::RubyLLM::IMAGE_MODEL}", result[:message_to_user], "The user should see which model made the image"
    end
  end

  test "generate_an_image falls back to the user's Gemini service without an OpenAI service" do
    api_services(:keith_openai_service).update!(deleted_at: Time.current)

    Current.set(user: users(:keith), message: messages(:image_generation_tool_call)) do
      result = @tool.generate_an_image(image_generation_prompt_s: @prompt)

      recorded = TestClient::RubyLLM::ContextDouble.last_paint_call
      assert_equal @prompt, recorded[:prompt], "The prompt should be passed to paint unchanged"
      assert_equal "keith-secret", recorded[:gemini_api_key], "Paint should use the user's Gemini key"
      assert_nil recorded[:openai_api_key], "No OpenAI-dialect key should be sent to Gemini"
      assert_equal AIBackend::RubyLLM::GEMINI_IMAGE_MODEL, recorded[:kwargs][:model], "Paint should use the Gemini image model"
      assert_equal :gemini, recorded[:kwargs][:provider], "Paint should target the Gemini provider"
      assert_equal "1024x1024", recorded[:kwargs][:size], "Paint should request a square image"
      assert_nil recorded[:kwargs][:provider_options], "OpenAI's quality option should not be sent to Gemini"

      assert_equal "RUBYLLM_BASE64_IMAGE_DATA", result[:json_of_generated_image], "The painted image data should come back to the job"
      assert_equal "Image created by tool using Gemini model #{AIBackend::RubyLLM::GEMINI_IMAGE_MODEL}", result[:message_to_user], "The user should see which model made the image"
    end
  end

  test "generate_an_image falls back to Gemini when the OpenAI service has no token" do
    stub_features(default_llm_keys: false) do
      api_services(:keith_openai_service).update!(token: nil)

      Current.set(user: users(:keith), message: messages(:image_generation_tool_call)) do
        result = @tool.generate_an_image(image_generation_prompt_s: @prompt)

        assert_equal :gemini, TestClient::RubyLLM::ContextDouble.last_paint_call[:kwargs][:provider], "A tokenless OpenAI service should not block the Gemini fallback"
        assert_equal "Image created by tool using Gemini model #{AIBackend::RubyLLM::GEMINI_IMAGE_MODEL}", result[:message_to_user], "The user should see which model made the image"
      end
    end
  end

  test "a Groq service (also driver openai) is not mistaken for the OpenAI image service" do
    users(:keith).api_services.where(name: ["OpenAI", "Google Gemini"]).update_all(deleted_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
    users(:keith).reload # drop the memoized api_services association so soft-deletes are visible

    Current.set(user: users(:keith), message: messages(:image_generation_tool_call)) do
      error = assert_raises(RuntimeError) { @tool.generate_an_image(image_generation_prompt_s: @prompt) }
      assert_includes error.message, "OpenAI or Gemini API key not found", "A missing OpenAI and Gemini key should be reported"
      assert_equal 1, error.message.scan(/to use image generation with/).length, "The assistant context should be appended exactly once"
    end
  end

  test "a Gemini proxy (custom URL) is not mistaken for the Gemini image service" do
    api_services(:keith_openai_service).update!(deleted_at: Time.current)
    api_services(:keith_gemini_service).update!(url: "https://gemini-gateway.example.com/")

    Current.set(user: users(:keith), message: messages(:image_generation_tool_call)) do
      error = assert_raises(RuntimeError) { @tool.generate_an_image(image_generation_prompt_s: @prompt) }
      assert_includes error.message, "OpenAI or Gemini API key not found", "Only the canonical Gemini service should paint"
    end
  end

  test "generate_an_image raises when neither the OpenAI nor the Gemini service has a token" do
    stub_features(default_llm_keys: false) do
      api_services(:keith_openai_service).update!(token: nil)
      api_services(:keith_gemini_service).update!(token: nil)

      Current.set(user: users(:keith), message: messages(:image_generation_tool_call)) do
        error = assert_raises(RuntimeError) { @tool.generate_an_image(image_generation_prompt_s: @prompt) }
        assert_includes error.message, "OpenAI or Gemini API key not found", "A missing OpenAI and Gemini key should be reported"
        assert_equal 1, error.message.scan(/to use image generation with/).length, "The assistant context should be appended exactly once"
      end
    end
  end

  test "generate_an_image surfaces the backend error when no OpenAI or Gemini service is configured" do
    users(:keith).api_services.update_all(deleted_at: Time.current) # rubocop:disable Rails/SkipsModelValidations
    users(:keith).reload # drop the memoized api_services association so soft-deletes are visible

    Current.set(user: users(:keith), message: messages(:image_generation_tool_call)) do
      error = assert_raises(RuntimeError) { @tool.generate_an_image(image_generation_prompt_s: @prompt) }
      assert_includes error.message, "OpenAI or Gemini API key not found", "A missing OpenAI and Gemini key should be reported"
      assert_equal 1, error.message.scan(/to use image generation with/).length, "The assistant context should be appended exactly once"
    end
  end

  test "a paint failure maps into the unified error contract and surfaces with the toolbox context" do
    TestClient::RubyLLM::ContextDouble.paint_error_to_raise = ::RubyLLM::UnauthorizedError.new("401 bad key")

    Current.set(user: users(:keith), message: messages(:image_generation_tool_call)) do
      error = assert_raises(RuntimeError) { @tool.generate_an_image(image_generation_prompt_s: @prompt) }
      assert_includes error.message, "401 bad key", "The provider's error should reach the user"
      assert_equal 1, error.message.scan(/to use image generation with/).length, "The assistant context should be appended exactly once"
    end
  end

  test "a Gemini paint failure names the Gemini image model" do
    api_services(:keith_openai_service).update!(deleted_at: Time.current)
    TestClient::RubyLLM::ContextDouble.paint_error_to_raise = ::RubyLLM::BadRequestError.new("API key not valid")

    Current.set(user: users(:keith), message: messages(:image_generation_tool_call)) do
      error = assert_raises(RuntimeError) { @tool.generate_an_image(image_generation_prompt_s: @prompt) }
      assert_includes error.message, "API key not valid", "Gemini's error should reach the user"
      assert_includes error.message, AIBackend::RubyLLM::GEMINI_IMAGE_MODEL, "The error should name the model that failed"
    end
  end

  test "a Gemini rate limit maps to Faraday::TooManyRequestsError" do
    api_services(:keith_openai_service).update!(deleted_at: Time.current)
    TestClient::RubyLLM::ContextDouble.paint_error_to_raise = ::RubyLLM::RateLimitError.new("quota exceeded")

    assert_raises(::Faraday::TooManyRequestsError) do
      AIBackend::RubyLLM.generate_image(prompt: @prompt, user: users(:keith))
    end
  end

  test "a Gemini reply without an image names the Gemini image model" do
    api_services(:keith_openai_service).update!(deleted_at: Time.current)
    TestClient::RubyLLM::ContextDouble.paint_error_to_raise = ::RubyLLM::Error.new("Unexpected response format from Gemini image generation API")

    raised = assert_raises(::Faraday::ServerError) do
      AIBackend::RubyLLM.generate_image(prompt: @prompt, user: users(:keith))
    end
    assert_includes raised.message, "Unexpected response format", "Gemini's failure should reach the user"
    assert_includes raised.message, AIBackend::RubyLLM::GEMINI_IMAGE_MODEL, "The error should name the model that failed"
  end
end
