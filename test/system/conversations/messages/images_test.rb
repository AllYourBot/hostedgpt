require "application_system_test_case"

class ConversationMessagesImagesTest < ApplicationSystemTestCase
  setup do
    preprocess_all_variants!

    @user = users(:keith)
    login_as @user
    @conversation = conversations(:attachments)
  end

  test "images render in messages WHEN pre-processed, clicking opens modal" do
    visit conversation_messages_path(@conversation)
    image_msg = find_messages.third

    image_btn = image_msg.find_role("image-preview")
    loader = image_btn.find_role("image-loader")
    img = image_btn.find("img", visible: :all)

    modal = image_msg.find_role("image-modal")

    wait_for_initial_scroll_down

    assert image_btn
    assert img
    refute loader.visible?, "loader should NEVER be visible in this test"
    wait_for_images_to_load

    refute modal.visible?

    image_btn.click

    assert_true "modal image should have been visible" do
      modal.visible?
    end

    send_keys "esc"
    assert_false "modal image should have closed/hidden itself" do
      modal.visible?
    end
  end

  test "images eventually render in messages WHEN NOT pre-processed, clicking opens modal" do
    stimulate_image_variant_processing do
      visit conversation_messages_path(@conversation)
      sleep 2 # TODO sometimes it's getting to img.visible? but then it disappears so I think it's running too quickly
      image_msg = find_messages.third
      image_btn = image_msg.find_role("image-preview")
      img = image_btn.find("img", visible: false)
      modal = image_msg.find_role("image-modal")
      assert image_btn
      assert img
      assert modal

      assert_true wait: 5 do
        img.visible?
      end
      assert img.visible?

      wait_for_images_to_load

      refute modal.visible?

      image_btn.click

      assert_true "modal image should have been visible but it was #{modal.visible?} and #{modal}" do
        modal.visible?
      end

      send_keys "esc"
      assert_false "modal image should have closed/hidden itself" do
        modal.visible?
      end
    end
  end

  test "ensure images display a spinner initially if they get a 404 and then eventually get replaced with the image" do
    stimulate_image_variant_processing do
      visit conversation_messages_path(@conversation)
      image_msg       = find_messages.third
      image_container = image_msg.find_role("image-preview")
      loader          = image_container.find_role("image-loader")
      img             = image_container.find("img", visible: :all)
      modal_container = image_msg.find_role("image-modal")
      modal_loader    = modal_container.find_role("image-loader")
      modal_img       = modal_container.find("img", visible: :all)

      assert_true "image loader should be visible", wait: 0.6 do
        loader.visible?
      end
      refute img.visible?

      image_container.click

      assert_true "modal image loader should be visible", wait: 0.6 do
        modal_loader.visible?
      end
      refute modal_img.visible?

      send_keys "esc"

      assert_false "image loader should have eventually disappeared", wait: 10 do
        loader.visible?
      end
      assert img.visible?
      wait_for_images_to_load

      image_container.click

      assert_true "modal image should be visible" do
        modal_img.visible?
      end
      refute modal_loader.visible?
    end
  end

  test "ensure page scrolls back down to the bottom after an image pops in late" do
    stimulate_image_variant_processing do
      visit conversation_messages_path(@conversation)
      image_msg       = find_messages.third
      image_container = image_msg.find_role("image-preview")
      img             = image_container.find("img", visible: :all)

      assert_at_bottom
      assert_scrolled_down do

        assert_false "all images should be visible" do
          all("[data-role='image-preview']", visible: :all).map(&:visible?).include?(false)
        end

        assert_true do
          img.visible?
        end
      end
      sleep 5 # TODO: if flappy tests still persist then there is an actual bug with image_loader scroll down
      assert_at_bottom
    end
  end

  test "images in previous messages remain after submitting a new message, they should not display a new spinner" do
    image_msg = img = nil
    stimulate_image_variant_processing do
      visit conversation_messages_path(@conversation)
      image_msg = find_messages.third
      img = image_msg.find_role("image-preview").find("img", visible: false)

      assert_true wait: 5 do
        img.visible?
      end
    end

    send_keys "hello?"
    send_keys "enter"

    assert_composer_blank
    assert img.visible?

    send_keys "hello?"
    send_keys "enter"

    assert_composer_blank
    assert img.visible?
  end

  private

  def preprocess_all_variants!
    Document.all.each do |d|
      d.send(:wait_for_file_variant_to_process!, :small)
      d.send(:wait_for_file_variant_to_process!, :large)
    end
  end

  def stimulate_image_variant_processing(&block)
    Document.stub_any_instance(:has_file_variant_processed?, false) do
      ActiveStorage::PostgresqlController.stub_any_instance(:decode_verified_key, simulate_not_preprocessed) do
        yield block
      end
    end
  end

  def simulate_not_preprocessed
    ->() do
      return nil if params[:retry_count].to_i < 5
      ActiveStorage.verifier.verified(params[:encoded_key], purpose: :blob_key)&.symbolize_keys
    end
  end
end
