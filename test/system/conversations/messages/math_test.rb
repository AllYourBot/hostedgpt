require "application_system_test_case"

class ConversationMessagesMathTest < ApplicationSystemTestCase
  MATH_CONTENT = 'Euler: $$e^{i\\pi}+1=0$$ and inline \\(x^2\\) here'.freeze

  setup do
    @user = users(:keith)
    login_as @user
    @conversation = conversations(:greeting)
    messages(:im_a_bot).update!(content_text: MATH_CONTENT)
    @stream_msg = @conversation.messages.create! assistant: @conversation.assistant, content_text: "Stub: ", role: :assistant
    visit_and_scroll_wait conversation_messages_path(@conversation)
  end

  test "math typesets on page load instead of showing raw delimiters" do
    msg = find("#message_#{messages(:im_a_bot).id}")
    msg.assert_selector(".katex")
    msg.assert_no_text("$$")
  end

  test "streamed math typesets after a turbo broadcast" do
    @stream_msg.update!(content_text: MATH_CONTENT)
    GetNextAIMessageJob.broadcast_updated_message(@stream_msg)

    assert_selector "#message_#{@stream_msg.id} .katex"
  end
end
