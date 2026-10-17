class SpeechesController < ApplicationController
  before_action :require_voice_feature

  def create
    # Temporary dispatch until cleanup deletes the legacy path: the flag must
    # steer speech back to the SDK backend during an incident, not just chat.
    audio = if Feature.use_ruby_llm?
      AIBackend::RubyLLM.generate_speech(text: params.require(:text), user: Current.user)
    else
      AIBackend::OpenAI.generate_speech(text: params.require(:text), user: Current.user)
    end
    send_data audio, type: "audio/wav", disposition: "inline"
  rescue AIBackend::ConfigurationError
    render json: { message: AIBackend::Policy::OpenAI.key_error_message }, status: :unprocessable_content
  rescue ::Faraday::Error
    render json: { message: "Failed to generate audio" }, status: :bad_gateway
  end

  private

  def require_voice_feature
    head :not_found unless Feature.voice?
  end
end
