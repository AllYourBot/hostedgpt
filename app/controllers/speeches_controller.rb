class SpeechesController < ApplicationController
  before_action :require_voice_feature

  def create
    audio = AIBackend::OpenAI.generate_speech(text: params.require(:text), user: Current.user)
    send_data audio, type: "audio/wav", disposition: "inline"
  rescue AIBackend::ConfigurationError
    render json: { message: AIBackend::OpenAI.key_error_message }, status: :unprocessable_content
  rescue ::Faraday::Error
    render json: { message: "Failed to generate audio" }, status: :bad_gateway
  end

  private

  def require_voice_feature
    head :not_found unless Feature.voice?
  end
end
