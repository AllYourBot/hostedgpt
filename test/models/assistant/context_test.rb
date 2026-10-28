require "test_helper"

class Assistant::ContextTest < ActiveSupport::TestCase
  setup do
    @assistant = assistants(:samantha)
  end

  test "context_prompt is nil when there are no readable documents" do
    assert_nil @assistant.context_prompt, "The fixture's only document has no file, so there is nothing to add to the prompt"
  end

  test "context_prompt wraps each readable file in a named block" do
    attach "test_document.txt", "text/plain"

    prompt = @assistant.context_prompt
    assert prompt.starts_with?("The following files have been provided as context"), "The prompt should introduce the files"
    assert_includes prompt, %|<file name="test_document.txt">|, "Each file should open a block named for it"
    assert_includes prompt, "This is a text document", "The file's text should be inlined"
    assert_includes prompt, "</file>", "Each file block should be closed"
  end

  test "context_prompt NAMES the context images when the model CAN see them" do
    @assistant.language_model.update!(supports_images: true)
    attach "cat.png", "image/png"

    assert_includes @assistant.context_prompt, "attached to the first message of the conversation", "The model should learn where the images are"
    assert_includes @assistant.context_prompt, "cat.png", "The image should be named"
  end

  test "context_prompt LEAVES OUT images when the model CANNOT see them" do
    @assistant.language_model.update!(supports_images: false)
    attach "cat.png", "image/png"

    assert_nil @assistant.context_prompt, "An image the model cannot see should not be mentioned"
  end

  test "context_prompt leaves out binary files that are neither text nor images" do
    @assistant.documents.create!(file: { io: StringIO.new("\x00\x01"), filename: "blob.bin", content_type: "application/octet-stream" })

    assert_nil @assistant.context_prompt, "A binary file cannot be read as text or attached"
  end

  test "context_prompt INLINES a PDF's text when the model CANNOT read PDFs" do
    @assistant.language_model.update!(supports_pdf: false)
    attach "quarterly.pdf", "application/pdf"

    assert_includes @assistant.context_prompt, %|<file name="quarterly.pdf">\nQuarterly numbers|, "The PDF's extracted text should be inlined"
    assert_empty @assistant.context_attachments, "The PDF should not also be attached"
  end

  test "context_prompt NAMES a PDF instead of inlining its text when the model CAN read PDFs" do
    @assistant.language_model.update!(supports_pdf: true)
    attach "quarterly.pdf", "application/pdf"

    refute_includes @assistant.context_prompt, "Quarterly numbers", "The PDF is attached natively, so its text should not be sent twice"
    assert_includes @assistant.context_prompt, "attached to the first message of the conversation", "The model should learn where the PDF is"
    assert_includes @assistant.context_prompt, "quarterly.pdf", "The PDF should be named"
  end

  test "context_attachments lists only the documents the model reads natively, oldest first" do
    @assistant.language_model.update!(supports_images: true, supports_pdf: true)
    attach "test_document.txt", "text/plain"
    image = attach "cat.png", "image/png"
    pdf = attach "quarterly.pdf", "application/pdf"

    assert_equal [image, pdf], @assistant.context_attachments, "Text files stay in the prompt; images and PDFs are attached in upload order"
  end

  test "context_documents leaves out the images the assistant generated in its conversations" do
    @assistant.language_model.update!(supports_images: true)
    image = attach "cat.png", "image/png"
    message = messages(:image_generation_explained)
    GeneratedImage.new(Base64.strict_encode64(file_fixture("cat.png").binread)).attach_to!(message)
    assert_equal @assistant, message.documents.last.assistant, "The generated image should still record the assistant that made it"

    assert_equal [documents(:background), image], @assistant.context_documents, "Only the files uploaded as context should be listed"
    assert_equal [image], @assistant.context_attachments, "A generated image should not be attached to every new conversation"
    refute_includes @assistant.context_prompt, "generated.png", "A generated image should not be named as context"
  end

  private

  def attach(filename, content_type)
    file = Rack::Test::UploadedFile.new(file_fixture(filename), content_type)
    @assistant.documents.create!(file: file)
  end
end
