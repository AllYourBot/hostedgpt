require "application_system_test_case"

class MessagesComposerMicrophoneTest < ApplicationSystemTestCase
  include MicrophoneHelper

  setup do
    @user = users(:keith)
    login_as @user
  end

  test "when the user has voice feature disabled, composer does not ever show mic" do
    stub_features(voice: false) do
      visit new_assistant_message_path(assistants(:samantha))
      assert_no_selector "#composer #microphone-enable"
    end
  end

  test "when the user has voice feature enabled, composer shows a mic icon before text is entered, and hides the mic after text" do
    stub_features(voice: true) do
      visit new_assistant_message_path(assistants(:samantha))
      assert enable_mic.visible?

      send_keys "H"
      refute enable_mic.visible?

      send_keys "backspace"
      assert enable_mic.visible?
    end
  end

  test "when mic is clicked it turns red, when red mic is clicked it reverts back" do
    stub_features(voice: true) do
      visit new_assistant_message_path(assistants(:samantha))
      assert enable_mic.visible?
      refute disable_mic.visible?

      enable_mic.click
      refute enable_mic.visible?
      assert disable_mic.visible?

      disable_mic.click
      assert enable_mic.visible?
      refute disable_mic.visible?
    end
  end

  test "when mic keyboard shortcut is used it turns red, and clicking the text area reverts it back and lets you edit the text" do
    stub_features(voice: true) do
      visit new_assistant_message_path(assistants(:samantha))
      assert enable_mic.visible?
      refute disable_mic.visible?

      send_keys "meta+m"
      refute enable_mic.visible?
      assert disable_mic.visible?

      page.execute_script("document.querySelector(`#composer textarea`).value = 'Hello?'")

      click_element "#composer-overlay"
      refute disable_mic.visible?
      assert_equal "Hello?", composer.value
    end
  end
end
