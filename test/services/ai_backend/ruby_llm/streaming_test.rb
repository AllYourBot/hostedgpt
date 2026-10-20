require "test_helper"

# Probes the real 2.0 gem through the full backend: a
# GetNextAIMessageJob::ResponseCancelled raised inside the chunk block must
# propagate out of stream_next_conversation_message unchanged, so the Stop
# button keeps working. The TestClient fake cannot verify this — it propagates
# block raises by construction. WebMock supplies the SSE stream.
class AIBackend::RubyLLM::StreamingTest < ActiveSupport::TestCase
  OPENAI_URL = "https://api.openai.com/v1/chat/completions"

  test "a cancel raised inside the generate chunk block propagates out of stream_next_conversation_message" do
    stub_request(:post, OPENAI_URL).to_return(
      status: 200,
      headers: { "Content-Type" => "text/event-stream" },
      body: <<~SSE
        data: {"id":"chatcmpl-1","object":"chat.completion.chunk","model":"gpt-4o","choices":[{"index":0,"delta":{"role":"assistant","content":"Hel"},"finish_reason":null}]}

        data: {"id":"chatcmpl-1","object":"chat.completion.chunk","model":"gpt-4o","choices":[{"index":0,"delta":{"content":"lo"},"finish_reason":null}]}

        data: [DONE]

      SSE
    )

    user = users(:keith)
    assistant = assistants(:keith_gpt4)
    assistant.language_model.update!(supports_tools: false)
    conversation = Conversation.create!(user: user, assistant: assistant, title: "Cancel probe")
    conversation.messages.create!(role: :user, content_text: "Say hello", assistant: assistant)
    message = conversation.messages.create!(role: :assistant, content_text: nil, assistant: assistant, version: :latest)
    backend = AIBackend::RubyLLM.new(user, assistant, conversation, message)

    AIBackend::RubyLLM.stub :gem_class, ::RubyLLM::Chat do
      AIBackend::RubyLLM.stub :client, ::RubyLLM do
        assert_raises(GetNextAIMessageJob::ResponseCancelled) do
          backend.stream_next_conversation_message { |_chunk| raise GetNextAIMessageJob::ResponseCancelled }
        end
      end
    end
  end
end
