require "application_system_test_case"

class ConversationMessagesImagesTest < ApplicationSystemTestCase
  setup do
    @user = users(:keith)
    login_as @user
    @conversation = conversations(:attachments)
    visit conversation_messages_path(@conversation)
    @image_msg = find_messages.third
  end

  test "images render in messages, clicking opens modal" do
    image = node("image-preview", within: @image_msg)
    modal = @image_msg.find("[data-role='image-modal']", visible: false)

    assert image
    refute modal.visible?
    image.click
    assert modal.visible?
    send_keys "esc"
    refute modal.visible?
  end
end
