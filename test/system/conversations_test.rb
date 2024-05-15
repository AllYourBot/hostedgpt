require "application_system_test_case"

class ConversationsTest < ApplicationSystemTestCase
  setup do
    login_as users(:keith)
    @starting_path = current_path
  end

  test "edit icon shows a tooltip" do
    convo = hover_conversation conversations(:greeting)
    assert_shows_tooltip convo.find_role("edit"), "Rename"
  end

  test "clicking conversation edits icon enables edit, unfocusing submits it" do
    convo = hover_conversation conversations(:greeting)
    convo.find_role("edit").click

    fill_in "edit-conversation", with: "Meeting Samantha Jones"
    find("body").click
    sleep 1

    assert_equal "Meeting Samantha Jones", convo.text
    assert_equal "Meeting Samantha Jones", conversations(:greeting).reload.title
  end

  test "clicking conversation edits icon enables edit, pressing Enter submits it" do
    convo = hover_conversation conversations(:greeting)
    convo.find_role("edit").click

    fill_in "edit-conversation", with: "Meeting Samantha Jones"
    send_keys "enter"
    sleep 1

    assert_equal "Meeting Samantha Jones", convo.text
    assert_equal "Meeting Samantha Jones", conversations(:greeting).reload.title
  end

  test "clicking conversation edits it and pressing Esc aborts the edit and does not save" do
    convo = hover_conversation conversations(:greeting)
    convo.find_role("edit").click

    fill_in "edit-conversation", with: "Meeting Samantha Jones"
    send_keys "esc"
    sleep 0.2

    assert_equal "Meeting Samantha", convo.text
    assert_equal "Meeting Samantha", conversations(:greeting).reload.title
  end

  test "delete icon shows a tooltip" do
    convo = hover_conversation conversations(:greeting)
    assert_shows_tooltip convo.find_role("delete"), "Delete"
  end

  test "clicking the conversation delete, when you ARE NOT on this conversation, deletes it and the url does not change" do
    convo = hover_conversation conversations(:greeting)
    delete = convo.find_role("delete")
    confirm_delete = convo.find_role("confirm-delete")

    delete.click
    assert_true { confirm_delete.visible? }
    confirm_delete.click

    assert_toast "Deleted conversation"
    assert_current_path(@starting_path)
  end

  test "clicking the conversation delete, when you ARE not on this conversation, deletes it and redirects you to a new conversation" do
    visit_and_scroll_wait conversation_messages_path(conversations(:greeting))
    convo = hover_conversation conversations(:greeting)
    delete = convo.find_role("delete")
    confirm_delete = convo.find_role("confirm-delete")

    delete.click
    assert_true { confirm_delete.visible? }
    confirm_delete.click

    assert_toast "Deleted conversation"
    assert_current_path new_assistant_message_path(users(:keith).assistants.ordered.first)
  end

  private

  def hover_conversation(c)
    assert_visible "#conversation-#{c.id} a[data-role='title']"
    convo_node = find("#conversation-#{c.id}")
    convo_node.hover
    convo_node
  end
end
