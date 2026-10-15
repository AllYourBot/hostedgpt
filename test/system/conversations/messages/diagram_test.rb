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
    assert_includes msg.text, "not a diagram"
  end

  test "streamed diagram previews after a turbo broadcast" do
    @stream_msg.update!(content_text: DIAGRAM_CONTENT)
    GetNextAIMessageJob.broadcast_updated_message(@stream_msg)

    assert_selector "#message_#{@stream_msg.id} .mermaid-preview svg"
  end
end
