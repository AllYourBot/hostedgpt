# frozen_string_literal: true

# Steps for the thinking expansion, mirroring test/system/messages/thinking_test.rb.

Given("the greeting conversation's last assistant reply is thinking {string}") do |text|
  conversations(:greeting).messages.where(role: :assistant).last.update!(thinking_text: text)
end

When("I press the thinking summary arrow") do
  details = find("[data-role='thinking-text']")
  summary = details.find("summary")

  left_edge_of_summary = -(summary.native.rect.width / 2).to_i + 1
  page.driver.browser.action
    .move_to(summary.native, left_edge_of_summary, 0)
    .click_and_hold.pause(duration: 0.4).release.perform
end
