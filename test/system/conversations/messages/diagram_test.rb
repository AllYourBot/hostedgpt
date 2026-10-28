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

    # Out of the failed-render window (debounce + first mermaid warm-up):
    # mermaid's temp wrapper (a direct body child) and the message-scoped
    # error svg would still be in the DOM now if the catch-path cleanup
    # missed them. Direct-body-child scoping keeps valid preview svgs on
    # other messages out of this count.
    sleep 2.5
    message_scope = "#message_#{messages(:im_a_bot).id}"
    leftovers = page.evaluate_script(
      "document.querySelectorAll(\"body > div[id^='dmermaid-']\").length" \
      " + document.querySelectorAll(\"#{message_scope} .mermaid-preview svg\").length"
    )
    assert_equal 0, leftovers, "mermaid's failed-render artifacts must not linger outside the message"
  end

  test "a cached diagram re-renders under the current theme after a flip" do
    msg = find("#message_#{messages(:im_a_bot).id}")
    assert msg.has_selector?(".mermaid-preview svg"), "the first render produced a preview"
    first_id = msg.find(".mermaid-preview svg")[:id]

    # Module-level mermaid state survives Turbo visits, so an in-app theme
    # flip (settings turbo form, page never reloads) must re-key the cache.
    # Choose the flip direction from the browser's preferred scheme so the
    # effective mermaid theme definitely changes. The preview-removal below
    # is the actual DOM mutation the observer sees (attribute and flag
    # changes are unobserved); it schedules a fresh theme-checked render
    # pass, which must mint a new svg id instead of reusing the cached one.
    if page.evaluate_script("matchMedia('(prefers-color-scheme: dark)').matches")
      page.execute_script(
        "document.documentElement.classList.remove('dark','system');" \
        "document.body.classList.remove('dark','system')"
      )
    else
      page.execute_script("document.documentElement.classList.add('dark'); document.body.classList.add('dark')")
    end
    page.execute_script(
      "document.querySelectorAll('[data-diagram-rendered]').forEach(n => delete n.dataset.diagramRendered);" \
      "document.querySelectorAll('.mermaid-preview').forEach(n => n.remove())"
    )

    fresh = page.find("#message_#{messages(:im_a_bot).id} .mermaid-preview svg", visible: :all, wait: 5)
    assert_not_equal first_id, fresh[:id],
      "a theme flip must evict the cache so cached diagrams re-render under the current theme"
  end

  test "mid-stream broadcast leaves readable source and no flashing preview" do
    @stream_msg.update!(content_text: DIAGRAM_CONTENT)
    GetNextAIMessageJob.broadcast_updated_message(@stream_msg, thinking: true)

    msg = find("#message_#{@stream_msg.id}")
    assert msg.has_selector?("[data-role='content-text'][data-streaming='true']"),
      "the streamed message flags its content div as streaming"

    # Out of the observer debounce: an ungated render would have run by now.
    sleep 0.6
    assert_equal 0, page.evaluate_script(
      "document.querySelectorAll('#message_#{@stream_msg.id} .mermaid-preview, #message_#{@stream_msg.id} [data-diagram-rendered]').length"
    ), "the diagram preview must not render while the reply streams"
    assert msg.has_text?("A-->B"), "the diagram source stays readable mid-stream"
  end

  test "streamed diagram previews after a turbo broadcast" do
    @stream_msg.update!(content_text: DIAGRAM_CONTENT)
    GetNextAIMessageJob.broadcast_updated_message(@stream_msg)

    assert page.has_selector?("#message_#{@stream_msg.id} .mermaid-preview svg"),
      "the settled diagram previews as a diagram"
    assert page.has_selector?("#message_#{@stream_msg.id} [data-role='content-text'][data-streaming='false']"),
      "the settle broadcast flips the render gate back off"
  end
end
