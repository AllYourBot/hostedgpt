require "application_system_test_case"

class ConversationMessagesDiagramTest < ApplicationSystemTestCase
  DIAGRAM_CONTENT = "Flow:\n\n```mermaid\ngraph TD;\n  A-->B;\n```\n".freeze

  setup do
    @user = users(:keith)
    login_as @user
    @conversation = conversations(:greeting)
    messages(:im_a_bot).update!(content_text: DIAGRAM_CONTENT)
    @stream_msg = @conversation.messages.create! assistant: @conversation.assistant, content_text: "Stub: ", role: :assistant
    visit_and_scroll_wait conversation_messages_path(@conversation)
  end

  test "mermaid block renders a diagram preview and keeps its source" do
    msg = find("#message_#{messages(:im_a_bot).id}")
    msg.assert_selector(".mermaid-preview svg")
    msg.assert_selector("details", text: "Diagram source")
    msg.assert_selector("details pre", text: "A-->B", visible: :all)
  end

  test "invalid diagram leaves readable source and breaks nothing" do
    messages(:im_a_bot).update!(content_text: "Bad:\n\n```mermaid\nnot a diagram {{{\n```\n")
    visit_and_scroll_wait conversation_messages_path(@conversation)

    msg = find("#message_#{messages(:im_a_bot).id}")
    msg.assert_no_selector(".mermaid-preview svg")
    assert_includes msg.text, "not a diagram", "the broken fence stays as readable source"

    # Out of the render window itself (debounce + first mermaid warm-up):
    # any mermaid error artifacts would still be in the DOM now and the
    # catch-side cleanup removes them.
    sleep 1.5
    leftovers = page.evaluate_script(
      "document.querySelectorAll(\"div[id^='dmermaid-'], svg[id^='mermaid-']\").length"
    )
    assert_equal 0, leftovers, "mermaid's failed-render artifacts must not linger outside the message"
  end

  test "mid-stream broadcast leaves readable source and no flashing preview" do
    @stream_msg.update!(content_text: DIAGRAM_CONTENT)
    GetNextAIMessageJob.broadcast_updated_message(@stream_msg, thinking: true)

    assert_no_selector "#message_#{@stream_msg.id} .mermaid-preview svg"
    assert_includes last_message.text, "A-->B"
  end

  test "streamed diagram previews after a turbo broadcast" do
    @stream_msg.update!(content_text: DIAGRAM_CONTENT)
    GetNextAIMessageJob.broadcast_updated_message(@stream_msg)

    assert page.has_selector?("#message_#{@stream_msg.id} .mermaid-preview svg"),
      "the settled diagram previews as a diagram"
  end
end
