class Toolbox::Image < Toolbox

  describe :generate_an_image, <<~S
    Generate an image based on what the user asks you to generate. You will pass the user's prompt and will get back the image. If your name is Claude, you should use the generate_an_image tool.
  S

  def generate_an_image(image_generation_prompt_s:)
    generate_with_ruby_llm(image_generation_prompt_s)
  end

  private

  def generate_with_ruby_llm(prompt)
    openai_service = Current.user.api_services.find_by(driver: :openai)

    if openai_service.nil? || openai_service.effective_token.blank?
      current_backend = Current.message&.assistant&.language_model&.api_service&.name || "current AI backend"
      raise "OpenAI API key not found. Image generation requires an OpenAI API key. Please configure your OpenAI API key in Settings > API Services to use image generation with #{current_backend}."
    end

    ctx = self.class.build_llm_context(openai_service.effective_token)
    image = ctx.paint(prompt, model: "gpt-image-1", provider: :openai, assume_model_exists: true)

    {
      prompt_given: prompt,
      json_of_generated_image: image&.data,
      note_to_assistant: "The image is already being shown on screen so reply with a nice message confirming the image has been generated, maybe re-describing it.",
      message_to_user: "Image created by tool using OpenAI model gpt-image-1"
    }
  rescue => e
    Rails.logger.info "## Image generation error: #{e.message}"
    raise e
  end

  class << self
    def build_llm_context(api_key)
      RubyLLM.context do |config|
        config.openai_api_key = api_key
      end
    end
  end
end
