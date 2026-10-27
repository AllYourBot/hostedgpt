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

    assert page.has_selector?("#message_#{@stream_msg.id} .katex"),
      "the settled math typesets"
    assert page.has_selector?("#message_#{@stream_msg.id} [data-role='content-text'][data-streaming='false']"),
      "the settle broadcast flips the render gate back off"
  end

  test "mid-stream broadcast leaves math as readable source" do
    @stream_msg.update!(content_text: MATH_CONTENT)
    GetNextAIMessageJob.broadcast_updated_message(@stream_msg, thinking: true)

    msg = find("#message_#{@stream_msg.id}")
    assert msg.has_selector?("[data-role='content-text'][data-streaming='true']"),
      "the streamed message flags its content div as streaming"

    # Out of the observer debounce: an ungated typeset would have run by now.
    sleep 0.6
    assert_equal 0, page.evaluate_script(
      "document.querySelectorAll('#message_#{@stream_msg.id} .katex').length"
    ), "KaTeX must not re-typeset while the reply streams"
    assert msg.has_text?("$$e^{i\\pi}+1=0$$"), "the math source stays readable mid-stream"
  end
end
