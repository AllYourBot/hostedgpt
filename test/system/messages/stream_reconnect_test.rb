require "application_system_test_case"

class StreamReconnectTest < ApplicationSystemTestCase
  setup do
    @user = users(:keith)
    login_as @user
    @conversation = conversations(:greeting)
  end

  test "a reply missed while the stream was disconnected appears once it reconnects" do
    visit_and_scroll_wait conversation_messages_path(@conversation)
    assert_selector "turbo-cable-stream-source[connected]", visible: false

    messages(:photo_identified).update_column(:content_text, "Missed while disconnected")
    refute_text "Missed while disconnected"

    toggle_stream_connection
    assert_text "Missed while disconnected"
  end

  test "a page morph does not count as a dropped connection" do
    visit_and_scroll_wait conversation_messages_path(@conversation)
    page.execute_script(<<~JS)
      document.addEventListener("turbo:morph", () => document.body.dataset.morphed = "true", { once: true })
      Turbo.session.refresh(location.href)
    JS
    assert_selector "body[data-morphed]"
    assert_selector "turbo-cable-stream-source[connected]", visible: false
  end

  private

  def toggle_stream_connection
    page.execute_script(<<~JS)
      const stream = document.querySelector("turbo-cable-stream-source")
      stream.removeAttribute("connected")
      setTimeout(() => stream.setAttribute("connected", ""), 50)
    JS
  end
end
