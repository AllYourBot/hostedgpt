require "application_system_test_case"

class NavColumnTest < ApplicationSystemTestCase
  setup do
    @user = users(:keith)
    login_as @user
  end

  test "clicking conversation in the left column updates the right and preserves scroll position of the left" do
    conversation = conversations(:attachment)

    assert_text conversation.title # wait for the lazy-loaded #nav-conversations frame to render before scrolling it, otherwise scrollTop below silently clamps to 0
    wait_for_images_to_load
    scroll_to_position "#nav-scrollable", 100 # scroll the nav column down slightly
    assert_scroll_position "#nav-scrollable", 100

    click_text conversation.title
    # The click is only finished once the right column has swapped in the conversation. Judging the nav
    # column's scroll while that is still in flight is what made this test flakey.
    assert_current_path conversation_messages_path(conversation, version: 1)
    assert_first_message conversation.messages.ordered.first

    assert_scroll_position "#nav-scrollable", 100, "Clicking a conversation should not have scrolled the nav column"
  end

  test "clicking a conversation title from the assistants page (before visiting any chat) loads the conversation" do
    with_assistants_page(true) do
      login_as @user
      visit root_url
      assert_current_path root_path # the Assistants index page itself, not a chat page

      click_text conversations(:greeting).title
      assert_current_path conversation_messages_path(conversations(:greeting), version: 1)
      assert_first_message conversations(:greeting).messages.ordered.first
    end
  end

  test "clicking conversations in the left side updates the right column and path when assistants page is enabled" do
    with_assistants_page(true) do
      assistant = @user.assistants.ordered.first

      login_as @user
      visit root_url
      assert_current_path root_path
      visit new_assistant_message_path(assistant)
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
    end
  end

  test "clicking conversations in the left side updates the right column and path when assistants page is disabled" do
    with_assistants_page(false) do
      assistant = @user.assistants.ordered.first

      login_as @user
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
    end
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
