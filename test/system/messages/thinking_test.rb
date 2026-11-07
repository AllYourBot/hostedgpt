require "application_system_test_case"

class ThinkingTest < ApplicationSystemTestCase
  setup do
    @user = users(:keith)
    login_as @user
    @conversation = conversations(:greeting)
    @conversation.messages.where(role: :assistant).last.update!(thinking_text: "Pondering the greeting")
  end

  test "pressing the arrow beside Thinking expands the thinking text" do
    visit_and_scroll_wait conversation_messages_path(@conversation)
    details = find("[data-role='thinking-text']")
    summary = details.find("summary")

    left_edge_of_summary = -(summary.native.rect.width / 2).to_i + 1
    page.driver.browser.action
      .move_to(summary.native, left_edge_of_summary, 0)
      .click_and_hold.pause(duration: 0.4).release.perform

    assert_text "Pondering the greeting"
  end
end
