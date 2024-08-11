require "application_system_test_case"

class MessagesComposerAttachmentTest < ApplicationSystemTestCase
  setup do
    @user = users(:keith)
    login_as @user
    @submit = find("#composer #send", visible: :all) # oddly, when I changed id="submit" on the button the form fails to submit
    @input_selector = "#composer textarea"
    @input = find(@input_selector)
  end

  test "attaching an image to the composer shows a preview, keeps submit hidden, and refocuses input" do
    assert_hidden "#document-previews"
    attach_file "message_documents_attributes_0_file", Rails.root.join('test', 'assets', 'cat-image-for-attaching.png'), make_visible: true

    assert find_previews.first.visible?
    assert find("#document-previews img")[:src].starts_with?("data:image")
    refute @submit.visible?
    assert_active @input_selector
  end

  test "attaching an image and clicking X removes the image" do
    attach_file "message_documents_attributes_0_file", Rails.root.join('test', 'assets', 'cat-image-for-attaching.png'), make_visible: true

    assert find_previews.first.visible?
    assert find("#document-previews img")[:src].starts_with?("data:image")

    find_previews.first.hover
    x = find_previews.first.find("[data-role='preview-remove']")
    assert_shows_tooltip x, "Remove file"
    x.click

    assert_hidden "#document-previews"
    refute @submit.visible?
    assert_active @input_selector
  end

  # TODO: Add a test for submitting this and ensuring it gets attached to the message
  # TODO: Add tests for attaching multiple images

  private

  def find_previews
    all("#document-previews [data-role='preview']").to_a
  end

end