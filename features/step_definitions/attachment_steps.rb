# frozen_string_literal: true

# Steps for composer attachments, mirroring
# test/system/messages/composer/attachment_test.rb.

CAT_IMAGE = Rails.root.join("test", "assets", "cat-image-for-attaching.png")

Then("the document previews are hidden") do
  assert_hidden "#document-previews"
end

When("I attach the cat image") do
  attach_file "message_documents_attributes_0_file", CAT_IMAGE, make_visible: true
end

When("I attach two cat images") do
  attach_file "attachment_picker", [CAT_IMAGE, CAT_IMAGE], make_visible: true
end

Then("a preview is shown with a data-uri image") do
  assert find_previews.first.visible?
  assert find("#document-previews img")[:src].starts_with?("data:image")
end

Then("two previews are shown and visible") do
  assert_equal 2, find_previews.length
  find_previews.each { assert it.visible? }
end

When("I remove the first preview via its X") do
  find_previews.first.hover
  x = find_previews.first.find("[data-role='preview-remove']")
  assert_shows_tooltip x, "Remove file"
  x.click
end

When("I remove the first preview") do
  find_previews.first.hover
  find_previews.first.find("[data-role='preview-remove']").click
end

Then("one preview remains and it is visible") do
  assert_equal 1, find_previews.length
  assert find("#document-previews").visible?
end

def find_previews = all("#document-previews [data-role='preview']").to_a
