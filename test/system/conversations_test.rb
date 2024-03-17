require "application_system_test_case"

class ConversationsTest < ApplicationSystemTestCase
  setup do
    login_as users(:keith)
  end

  test "creating new chat with meta+shift+o" do
    visit conversation_messages_path(conversations(:greeting))
    send_keys("meta+shift+o")

    expected_path = new_assistant_message_path(conversations(:greeting).assistant)

    assert_current_path(expected_path)
  end

  test "creating new chat with meta+j" do
    visit conversation_messages_path(conversations(:javascript))
    send_keys("meta+j")

    expected_path = new_assistant_message_path(conversations(:javascript).assistant)

    assert_current_path(expected_path)
  end

  test "clicking conversation edits it and unfocusing it submits it" do
    c = conversations(:greeting)

    assert_visible "#conversation-#{c.id} a"
    find("#conversation-#{c.id} a").hover
    click_element "#conversation-#{c.id} a[data-role='pencil']"
    assert_no_selector "#conversation-#{c.id} a"

    fill_in "edit-conversation", with: "Meeting Samantha Jones"
    find("body").click
    assert_visible "#conversation-#{c.id} a", wait: 0.5

    assert_equal "Meeting Samantha Jones", c.reload.title
  end

  test "clicking conversation edits it and pressing Enter submits it" do
    c = conversations(:greeting)

    assert_visible "#conversation-#{c.id} a"
    find("#conversation-#{c.id} a").hover
    click_element "#conversation-#{c.id} a[data-role='pencil']"
    assert_no_selector "#conversation-#{c.id} a"

    fill_in "edit-conversation", with: "Meeting Samantha Jones"
    send_keys "enter"
    assert_visible "#conversation-#{c.id} a", wait: 0.5

    assert_equal "Meeting Samantha Jones", c.reload.title
  end

  test "clicking conversation edits it and pressing Esc aborts the edit and does not savre" do
    c = conversations(:greeting)

    assert_visible "#conversation-#{c.id} a"
    find("#conversation-#{c.id} a").hover
    click_element "#conversation-#{c.id} a[data-role='pencil']"
    assert_no_selector "#conversation-#{c.id} a"

    fill_in "edit-conversation", with: "Meeting Samantha Jones"
    send_keys "esc"
    assert_visible "#conversation-#{c.id} a", wait: 0.5

    assert_equal "Meeting Samantha", c.reload.title
  end
end
