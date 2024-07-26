require "application_system_test_case"

class MessagesComposerSubmittingTest < ApplicationSystemTestCase
  include NavigationHelper

  setup do
    @user = users(:keith)
    login_as @user
    @submit = find("#composer #send", visible: :all)
    @long_conversation = conversations(:greeting)
  end

  test "submit button is hidden and can only be clicked when text is entered" do
    path = current_path

    refute @submit.visible?
    send_keys "Entered text so we can now submit"
    assert @submit.visible?
    click_element @submit

    assert_composer_blank
    assert_equal conversation_messages_path(@user.conversations.ordered.first), current_path, "Should have redirected to newly created conversation"
  end

  test "enter works to submit but only when text has been entered" do
    path = current_path

    refute @submit.visible?
    send_keys "enter"
    assert_equal path, current_path, "Path should not have changed because form should not submit"

    send_keys "Entered text so we can now submit"
    assert @submit.visible?
    assert_conversation_navigation_finished do
      send_keys "enter"
    end

    assert_composer_blank
    assert_equal conversation_messages_path(@user.conversations.ordered.first), current_path, "Should have redirected to newly created conversation"
  end

  test "shift+enter inserts a newline and then enter submits" do
    path = current_path

    send_keys "First line"
    send_keys "shift+enter"
    send_keys "Second line"
    assert_equal "First line\nSecond line", composer.value
    assert_equal path, current_path, "Path should not have changed because form should not submit"

    assert_conversation_navigation_finished do
      send_keys "enter"
    end

    assert_composer_blank
    assert_equal conversation_messages_path(@user.conversations.ordered.first), current_path, "Should have redirected to newly created conversation"
  end

  test "submitting a couple messages to an existing conversation with ENTER works" do
    visit_and_scroll_wait conversation_messages_path(@long_conversation)
    starting_path = current_path

    assert_active composer_selector
    assert_page_morphed do
      send_keys "This is a message"
      send_keys "enter"
    end

    assert_composer_blank
    assert_equal starting_path, current_path, "The page should not have changed urls"

    assert_page_morphed do
      send_keys "This is a second message"
      send_keys "enter"
    end

    assert_composer_blank
    assert_equal starting_path, current_path, "The page should not have changed urls"
  end

  test "submitting a couple messages to an existing conversation with CLICKING works" do
    visit_and_scroll_wait conversation_messages_path(@long_conversation)
    starting_path = current_path

    assert_active composer_selector
    assert_page_morphed do
      send_keys "This is a message"
      click_element @submit
    end

    assert_composer_blank
    assert_equal starting_path, current_path, "The page should not have changed urls"

    assert_page_morphed do
      send_keys "This is a second message"
      click_element @submit
    end

    assert_composer_blank
    assert_equal starting_path, current_path, "The page should not have changed urls"
  end
end
