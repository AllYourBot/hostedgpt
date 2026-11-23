# frozen_string_literal: true

# Steps for the stream reconnect behavior, mirroring
# test/system/messages/stream_reconnect_test.rb.

Then("the stream source is connected") do
  assert_selector "turbo-cable-stream-source[connected]", visible: false
end

When("the photo-identified message is updated to {string} without broadcasting") do |text|
  messages(:photo_identified).update_column(:content_text, text)
end

When("the stream connection is toggled") do
  page.execute_script(<<~JS)
    const stream = document.querySelector("turbo-cable-stream-source")
    stream.removeAttribute("connected")
    setTimeout(() => stream.setAttribute("connected", ""), 50)
  JS
end

When("the page is refreshed via Turbo.session.refresh") do
  page.execute_script(<<~JS)
    document.addEventListener("turbo:morph", () => document.body.dataset.morphed = "true", { once: true })
    Turbo.session.refresh(location.href)
  JS
end

Then("the body recorded a morph") do
  assert_selector "body[data-morphed]"
end
