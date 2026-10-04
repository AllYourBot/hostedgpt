class Toolbox::Image < Toolbox

  describe :generate_an_image, <<~S
    Generate an image based on what the user asks you to generate. You will pass the user's prompt and will get back the image. If your name is Claude, you should use the generate_an_image tool.
  S

  def generate_an_image(image_generation_prompt_s:)
    api_service = Current.message&.assistant&.language_model&.api_service
    result = generate_with_error_context(api_service&.ai_backend || AIBackend, api_service, image_generation_prompt_s)

    {
      prompt_given: image_generation_prompt_s,
      json_of_generated_image: result[:b64_json],
      note_to_assistant: "The image is already being shown on screen so reply with a nice message confirming the image has been generated, maybe re-describing it.",
      message_to_user: "Image created by tool using #{result[:provider]} model #{result[:model]}"
    }
  end

  private

  # The backend raises a context-free key error because it cannot know which
  # assistant wanted the image; this tool can, so the context is appended here.
  # StandardError, not RuntimeError: RubyLLM maps paint failures to ConfigurationError and Faraday errors.
  def generate_with_error_context(backend, api_service, prompt)
    backend.generate_image(prompt: prompt, user: Current.user)
  rescue StandardError => e
    current_backend = api_service&.name || "current AI backend"
    raise "#{e.message} to use image generation with #{current_backend}."
  end
end
