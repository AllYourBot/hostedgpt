# frozen_string_literal: true

# Steps for code block rendering and clipboard copying, mirroring
# test/system/conversations/messages/code_test.rb.

LONG_SQL_LINE = "SELECT users.id, users.email, accounts.name FROM users INNER JOIN accounts " \
  "ON accounts.id = users.account_id WHERE users.deleted_at IS NULL ORDER BY users.created_at DESC LIMIT 100;"

Then("the clipboard is empty") do
  assert_true { clipboard == "" }
end

Then("the clipboard holds {string}") do |text|
  assert_equal text, clipboard
end

Then("the clipboard holds the im-a-bot message's stripped content") do
  assert_equal messages(:im_a_bot).content_text.strip, clipboard
end

Then("the clipboard holds the javascript conversation's last message") do
  assert_true { conversations(:javascript).messages.ordered.last.content_text.strip == clipboard }
end

When("I copy the code block") do
  @code_msg = last_message
  @code_msg.find_role("code-clipboard").click
end

Then("the last message's code block header shows {string} and {string} but not {string}") do |first, second, absent|
  @code_msg = last_message
  assert_includes @code_msg.text, first, "#{first} should be in the header"
  assert_includes @code_msg.text, second, "#{second} should be in the header"
  refute_includes @code_msg.text, absent, "#{absent} should be in the header"
end

Then("the last message's code block header shows {string} but not {string}") do |present, absent|
  @code_msg = last_message
  assert_includes @code_msg.text, present, "#{present} should be in the header"
  refute_includes @code_msg.text, absent, "#{absent} should be in the header"
end

When("I copy the overall last message") do
  @code_msg = last_message
  @code_msg.hover
  @copy = @code_msg.find_role("clipboard")
  @copy.click
end

Then("the copy icon shows its {string} tooltip") do |text|
  assert_shows_tooltip @copy, text
end

When("I press the copy keyboard shortcut") do
  send_keys "meta+shift+c"
end

Given("the {string} message holds a long SQL line") do |fixture|
  messages(fixture.to_sym).update!(content_text: "Here you go:\n\n```sql\n#{LONG_SQL_LINE}\n```\n")
end

Then("the conversation shrinks with the viewport down to {int}px") do |narrowest|
  # Widths spanning the sidebar breakpoint (768px) down to very narrow.
  [900, 800, 768, 700, 500, 300].each do |width|
    page.driver.browser.execute_cdp("Emulation.setDeviceMetricsOverride",
      width: width, height: 800, deviceScaleFactor: 1, mobile: false)

    assert_true "at #{width}px the conversation should not be wider than the viewport" do
      page.evaluate_script("document.querySelector(\"turbo-frame#conversation\").getBoundingClientRect().width") <= width
    end

    assert_true "at #{width}px the page should not scroll horizontally" do
      page.evaluate_script("document.documentElement.scrollWidth") <= width + 5
    end
  end
ensure
  page.driver.browser.execute_cdp("Emulation.clearDeviceMetricsOverride")
end
