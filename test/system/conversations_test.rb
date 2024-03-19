require "application_system_test_case"

class ConversationsTest < ApplicationSystemTestCase
  setup do
    login_as users(:keith)
    @starting_path = current_path
    @starting_path = current_path
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

  test "edit icon shows a tooltip" do
    convo = hover_conversation conversations(:greeting)
    assert_shows_tooltip node("edit", within: convo), "Rename"
  end

  test "clicking conversation edits icon enables edit, unfocusing submits it" do
    convo = hover_conversation conversations(:greeting)
    node("edit", within: convo).click
  test "edit icon shows a tooltip" do
    convo = hover_conversation conversations(:greeting)
    assert_shows_tooltip node("edit", within: convo), "Rename"
  end

  test "clicking conversation edits icon enables edit, unfocusing submits it" do
    convo = hover_conversation conversations(:greeting)
    node("edit", within: convo).click

    fill_in "edit-conversation", with: "Meeting Samantha Jones"
    find("body").click
    sleep 0.2

    assert_equal "Meeting Samantha Jones", convo.text
    assert_equal "Meeting Samantha Jones", conversations(:greeting).reload.title
    sleep 0.2

    assert_equal "Meeting Samantha Jones", convo.text
    assert_equal "Meeting Samantha Jones", conversations(:greeting).reload.title
  end

  test "clicking conversation edits icon enables edit, pressing Enter submits it" do
    convo = hover_conversation conversations(:greeting)
    node("edit", within: convo).click
  test "clicking conversation edits icon enables edit, pressing Enter submits it" do
    convo = hover_conversation conversations(:greeting)
    node("edit", within: convo).click

    fill_in "edit-conversation", with: "Meeting Samantha Jones"
    send_keys "enter"
    sleep 0.2
    sleep 0.2

    assert_equal "Meeting Samantha Jones", convo.text
    assert_equal "Meeting Samantha Jones", conversations(:greeting).reload.title
    assert_equal "Meeting Samantha Jones", convo.text
    assert_equal "Meeting Samantha Jones", conversations(:greeting).reload.title
  end

  test "clicking conversation edits it and pressing Esc aborts the edit and does not save" do
    convo = hover_conversation conversations(:greeting)
    node("edit", within: convo).click
    convo = hover_conversation conversations(:greeting)
    node("edit", within: convo).click

    fill_in "edit-conversation", with: "Meeting Samantha Jones"
    send_keys "esc"
    sleep 0.2

    assert_equal "Meeting Samantha", convo.text
    assert_equal "Meeting Samantha", conversations(:greeting).reload.title
    sleep 0.2

    assert_equal "Meeting Samantha", convo.text
    assert_equal "Meeting Samantha", conversations(:greeting).reload.title
  end

  test "delete icon shows a tooltip" do
    convo = hover_conversation conversations(:greeting)
    assert_shows_tooltip node("delete", within: convo), "Delete"
  end

  test "clicking the conversation delete, when you ARE NOT on this conversation, deletes it and the url does not change" do
    convo = hover_conversation conversations(:greeting)
    delete = node("delete", within: convo)

    delete.click
  test "delete icon shows a tooltip" do
    convo = hover_conversation conversations(:greeting)
    assert_shows_tooltip node("delete", within: convo), "Delete"
  end

  test "clicking the conversation delete, when you ARE NOT on this conversation, deletes it and the url does not change" do
    convo = hover_conversation conversations(:greeting)
    delete = node("delete", within: convo)

    delete.click
    sleep 0.1
    confirm_delete = node("confirm-delete", within: convo)
    confirm_delete.click
    confirm_delete = node("confirm-delete", within: convo)
    confirm_delete.click

    assert_text "Deleted conversation", wait: 0.5
    refute convo.exists?
    assert_text "Deleted conversation", wait: 0.2
    refute convo.exists?

    assert_current_path(@starting_path)
    assert_current_path(@starting_path)
  end

  test "clicking the conversation delete, when you ARE not on this conversation, deletes it and redirects you to a new conversation" do
    visit conversation_messages_path(conversations(:greeting))
    convo = hover_conversation conversations(:greeting)
    delete = node("delete", within: convo)

    delete.click
    sleep 0.1
    confirm_delete = node("confirm-delete", within: convo)
    confirm_delete.click

    assert_text "Deleted conversation", wait: 0.5
    refute convo.exists?

    assert_current_path(new_assistant_message_path users(:keith).assistants.ordered.first)
  end

  private

  def hover_conversation(c)
    assert_visible "#conversation-#{c.id} a"
    convo_node = find("#conversation-#{c.id}")
    convo_node.hover
    convo_node
    visit conversation_messages_path(conversations(:greeting))
    convo = hover_conversation conversations(:greeting)
    delete = node("delete", within: convo)

    delete.click
    sleep 0.1
    confirm_delete = node("confirm-delete", within: convo)
    confirm_delete.click

    assert_text "Deleted conversation", wait: 0.2
    refute convo.exists?

    assert_current_path(new_assistant_message_path users(:keith).assistants.ordered.first)
  end

  private

  def hover_conversation(c)
    assert_visible "#conversation-#{c.id} a"
    convo_node = find("#conversation-#{c.id}")
    convo_node.hover
    convo_node
  end
end
