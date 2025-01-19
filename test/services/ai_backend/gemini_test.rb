require "test_helper"

class AIBackend::GeminiTest < ActiveSupport::TestCase
  setup do
    @conversation = conversations(:gemini_conversation)
    @assistant = assistants(:keith_gemini)
    @gemini = AIBackend::Gemini.new(
      users(:keith),
      @assistant,
      @conversation,
      @conversation.latest_message_for_version(:latest)
    )
  end

  test "initializing client works" do
    assert @gemini.client.present?
  end

  test "client uses effective api name for language model" do
    @assistant.language_model.stub :effective_api_name, 'test-effective' do
      @gemini = AIBackend::Gemini.new(
        users(:keith),
        @assistant,
        @conversation,
        @conversation.latest_message_for_version(:latest)
      )
      assert_equal 'test-effective', @gemini.client.init_args[:options][:model]
    end
  end
end
