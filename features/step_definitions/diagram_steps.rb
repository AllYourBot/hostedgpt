# frozen_string_literal: true

# Steps for mermaid diagram rendering, mirroring
# test/system/conversations/messages/diagram_test.rb.

DIAGRAM_CONTENT = "Flow:\n\n```mermaid\ngraph TD;\n  A-->B;\n```\n".freeze

Given("the {string} message holds a mermaid diagram") do |fixture|
  messages(fixture.to_sym).update!(content_text: DIAGRAM_CONTENT)
end

Given("the {string} message holds an invalid mermaid diagram") do |fixture|
  messages(fixture.to_sym).update!(content_text: "Bad:\n\n```mermaid\nnot a diagram {{{\n```\n")
end

When("the stub reply holds the diagram and broadcasts while thinking") do
  @stream_msg = conversations(:greeting).messages.ordered.last
  @stream_msg.update!(content_text: DIAGRAM_CONTENT)
  GetNextAIMessageJob.broadcast_updated_message(@stream_msg, thinking: true)
end

When("the stub reply holds the diagram and broadcasts") do
  @stream_msg = conversations(:greeting).messages.ordered.last
  @stream_msg.update!(content_text: DIAGRAM_CONTENT)
  GetNextAIMessageJob.broadcast_updated_message(@stream_msg)
end

Then("the diagram message previews as a diagram with its source in a disclosure") do
  msg = find("#message_#{messages(:im_a_bot).id}")
  assert msg.has_selector?(".mermaid-preview svg"), "the fence should preview as a diagram"
  assert msg.has_selector?("details", text: "Diagram source"), "the source should sit in a disclosure"
  assert msg.has_selector?("details pre", text: "A-->B", visible: :all), "the original source should be kept"
end

Then("the invalid diagram does not preview and its source stays readable") do
  msg = find("#message_#{messages(:im_a_bot).id}")
  assert msg.has_no_selector?(".mermaid-preview svg"), "an invalid diagram should not preview"
  assert_includes msg.text, "not a diagram", "the broken fence stays as readable source"
end

Then("past the debounce no failed-render artifacts linger") do
  # Past the debounce and mermaid's first warm-up, so a failed render has finished.
  sleep 2.5
  message_scope = "#message_#{messages(:im_a_bot).id}"
  leftovers = page.evaluate_script(
    "document.querySelectorAll(\"body > div[id^='dmermaid-']\").length" \
    " + document.querySelectorAll(\"#{message_scope} .mermaid-preview svg\").length"
  )
  assert_equal 0, leftovers, "mermaid's failed-render artifacts must not linger outside the message"
end

When("the theme flips and the diagram cache is evicted") do
  msg = find("#message_#{messages(:im_a_bot).id}")
  assert msg.has_selector?(".mermaid-preview svg"), "the first render produced a preview"
  @first_diagram_id = msg.find(".mermaid-preview svg")[:id]

  # Flip away from the browser's preferred scheme so the effective theme
  # really changes. Removing the previews is the mutation that triggers a
  # re-render; the class changes alone are unobserved.
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
end

Then("a fresh diagram renders under the current theme") do
  fresh = page.find("#message_#{messages(:im_a_bot).id} .mermaid-preview svg", visible: :all, wait: 5)
  assert_not_equal @first_diagram_id, fresh[:id],
    "a theme flip must evict the cache so cached diagrams re-render under the current theme"
end

Then("the streamed message flags its content div as streaming") do
  msg = find("#message_#{@stream_msg.id}")
  assert msg.has_selector?("[data-role='content-text'][data-streaming='true']"),
    "the streamed message flags its content div as streaming"
end

Then("the diagram preview must not render while the reply streams") do
  # Out of the observer debounce: an ungated render would have run by now.
  sleep 0.6
  assert_equal 0, page.evaluate_script(
    "document.querySelectorAll('#message_#{@stream_msg.id} .mermaid-preview, #message_#{@stream_msg.id} [data-diagram-rendered]').length"
  ), "the diagram preview must not render while the reply streams"
end

Then("the diagram source stays readable mid-stream") do
  assert find("#message_#{@stream_msg.id}").has_text?("A-->B"), "the diagram source stays readable mid-stream"
end

Then("the settled diagram previews as a diagram") do
  assert page.has_selector?("#message_#{@stream_msg.id} .mermaid-preview svg"),
    "the settled diagram previews as a diagram"
end

