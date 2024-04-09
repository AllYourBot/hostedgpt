require "application_system_test_case"

class ConversationMessagesImagesTest < ApplicationSystemTestCase
  setup do
    @user = users(:keith)
    login_as @user
    @conversation = conversations(:attachments)
  end

  test "images render in messages, clicking opens modal" do
    visit conversation_messages_path(@conversation)
    image_msg = find_messages.third

    image = image_msg.find_role("image-preview")
    modal = image_msg.find_role("image-modal")

    assert image
    refute modal.visible?

    image.click
    sleep 0.4
    assert modal.visible?

    send_keys "esc"
    sleep 0.4
    refute modal.visible?
  end

  test "images render in message and remain after submitting a new message which morphs the page" do
    visit conversation_messages_path(@conversation)
    image_msg = find_messages.third
    img = image_msg.find("img")

    assert img.visible?

    send_keys "hello?"
    send_keys "enter"

    sleep 0.5
    assert img.visible?

    send_keys "hello?"
    send_keys "enter"

    sleep 0.5
    assert img.visible?
  end

  test "ensure images display a spinner initially if they get a 404 and then eventually get replaced with the image" do
    decode_verified_key = ->() do
      return nil if params[:retry_count].to_i < 5
      ActiveStorage.verifier.verified(params[:encoded_key], purpose: :blob_key)&.symbolize_keys
    end

    ActiveStorage::PostgresqlController.stub_any_instance(:decode_verified_key, decode_verified_key) do
      visit conversation_messages_path(@conversation)
      image_msg       = find_messages.third
      image_container = image_msg.find_role("image-preview")
      loader          = image_container.find_role("loader")
      img             = image_container.find("img", visible: false)
      modal_container = image_msg.find_role("image-modal")
      modal_loader    = modal_container.find_role("loader")
      modal_img       = modal_container.find("img", visible: false)

      sleep 0.5
      assert loader.visible?
      refute img.visible?

      image_container.click
      sleep 0.2

      assert modal_loader.visible?
      refute modal_img.visible?

      send_keys "esc"
      sleep 3

      refute loader.visible?
      assert img.visible?

      image_container.click
      sleep 0.2

      refute modal_loader.visible?
      assert modal_img.visible?
    end
  end

  test "ensure page scrolls back down to the bottom after an image pops in late" do
    decode_verified_key = ->() do
      return nil if params[:retry_count].to_i < 5
      ActiveStorage.verifier.verified(params[:encoded_key], purpose: :blob_key)&.symbolize_keys
    end

    ActiveStorage::PostgresqlController.stub_any_instance(:decode_verified_key, decode_verified_key) do
      visit conversation_messages_path(@conversation)
      image_msg       = find_messages.third
      image_container = image_msg.find_role("image-preview")
      img             = image_container.find("img", visible: false)

      sleep 0.5
      assert_at_bottom

      while !img.visible?
        sleep 0.25
      end

      assert img.visible?
      sleep 0.5
      assert_at_bottom
    end
  end
end
