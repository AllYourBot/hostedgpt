require "application_system_test_case"

class NavColumnTest < ApplicationSystemTestCase
  setup do
    @user = users(:keith)
    login_as @user
  end

  test "clicking conversation in the left column updates the right and preserves scroll position of the left" do
    page.execute_script("document.querySelector('#nav-scrollable').scrollTop = 100") # scroll the nav column down slightly
    assert_did_not_scroll "#nav-scrollable" do
      click_text conversations(:attachment).title
    end
  end

  test "clicking conversations in the left side updates the right column, the path, and back button works as expected" do
    assistant = @user.assistants.ordered.first

    visit root_url

    assert_current_path new_assistant_message_path(assistant)
    assert_selected_assistant assistant

    click_text conversations(:greeting).title
    assert_current_path conversation_messages_path(conversations(:greeting), version: 1)
    assert_selected_assistant conversations(:greeting).assistant
    assert_first_message conversations(:greeting).messages.ordered.first

    click_text conversations(:javascript).title
    assert_current_path conversation_messages_path(conversations(:javascript), version: 1)
    assert_selected_assistant conversations(:javascript).assistant
    assert_first_message conversations(:javascript).messages.ordered.first

    click_text conversations(:ruby_version).title
    assert_current_path conversation_messages_path(conversations(:ruby_version), version: 1)
    assert_selected_assistant conversations(:ruby_version).assistant
    assert_first_message conversations(:ruby_version).messages.ordered.first

    # TODO: These two cases should be working but this test sporadically fails. I suspect that there is actually
    # bugginess in the back-state management of turbo but we need to dig in and figure out why.
    #
    # page.go_back
    # sleep 2
    # assert_current_path conversation_messages_path(conversations(:javascript))
    # assert_selected_assistant conversations(:javascript).assistant
    # assert_first_message conversations(:javascript).messages.ordered.first

    # page.go_back
    # sleep 2
    # assert_current_path conversation_messages_path(conversations(:greeting))
    # assert_selected_assistant conversations(:greeting).assistant
    # assert_first_message conversations(:greeting).messages.ordered.first

    # TODO: There is a bug with the latest turbo where the final back doesn't properly load from cache.
    #
    # page.go_back
    # sleep 2
    # assert_current_path new_assistant_message_path(assistant)
    # assert_selected_assistant assistant
  end

  test "nav column close handle shows proper tooltip and hides/shows column when clicked" do
    assert_visible "nav"

    assert_visible "#left-handle"
    assert_shows_tooltip "#left-handle", "Close sidebar"
    assert_hidden "#right-handle"

    click_element "#handle"
    assert_hidden "nav"

    assert_visible "#right-handle"
    assert_shows_tooltip "#right-handle", "Open sidebar"
    assert_hidden "#left-handle"

    click_element "#handle"
    assert_visible "nav"

    assert_visible "#left-handle"
    assert_shows_tooltip "#left-handle", "Close sidebar"
    assert_hidden "#right-handle"
  end

  test "refreshing the page after closing sidebar keeps it closed" do
    assert_visible "nav"
    click_element "#handle"
    sleep 0.3
    assert_hidden "nav"

    visit current_path
    assert_hidden "nav", "The nav bar should have stayed closed."
  end

  test "refreshing the page after closing and re-opening sidebar keeps it opened" do
    assert_visible "nav"
    click_element "#handle"
    assert_hidden "nav"

    click_element "#handle"
    assert_visible "nav"

    visit current_path
    assert_visible "nav", "The nav bar should have stayed opened."
  end

  test "meta+. opens and closes nav column" do
    assert_visible "nav"

    assert_visible "#left-handle"
    assert_hidden "#right-handle"

    send_keys "meta+."
    assert_hidden "nav"

    assert_visible "#right-handle"
    assert_hidden "#left-handle"

    send_keys "meta+."
    assert_visible "nav"

    assert_visible "#left-handle"
    assert_hidden "#right-handle"
  end

  test "meta+shift+s opens and closes nav column" do
    assert_visible "nav"

    assert_visible "#left-handle"
    assert_hidden "#right-handle"

    send_keys "meta+shift+s"
    assert_hidden "nav"

    assert_visible "#right-handle"
    assert_hidden "#left-handle"

    send_keys "meta+shift+s"
    assert_visible "nav"

    assert_visible "#left-handle"
    assert_hidden "#right-handle"
  end

  test "clicking the assistant name in the nav column starts a new conversation" do
    conversation_path = conversation_messages_path(conversations(:greeting), version: 1)
    visit conversation_path
    assert_current_path conversation_path

    assistant1 = @user.assistants.ordered.first
    click_text assistant1.name, match: :first
    assert_current_path new_assistant_message_path(assistant1)

    assistant2 = @user.assistants.ordered.second
    second_assistant_container = all("#assistants [data-role='assistant']", visible: :false)[1]
    second_assistant_container.hover
    pencil_on_second_assistant = all("#assistants a[data-role='new']", visible: :false)[1]
    assert_shows_tooltip pencil_on_second_assistant, "New"
    click_element pencil_on_second_assistant
    assert_current_path new_assistant_message_path(assistant2)
  end
end
