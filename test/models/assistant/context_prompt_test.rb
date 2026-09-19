require "test_helper"

class Assistant::ContextPromptTest < ActiveSupport::TestCase
  setup do
    @assistant = assistants(:samantha)
  end

  test "context_prompt is nil when there are no readable documents" do
    assert_nil @assistant.context_prompt
  end

  test "context_prompt wraps each readable file in a named block" do
    attach "test_document.txt", "text/plain"

    prompt = @assistant.context_prompt
    assert prompt.starts_with?("The following files have been provided as context")
    assert_includes prompt, %|<file name="test_document.txt">|
    assert_includes prompt, "This is a text document"
    assert_includes prompt, "</file>"
  end

  test "context_prompt leaves out files that cannot be read as text" do
    attach "cat.png", "image/png"

    assert_nil @assistant.context_prompt
  end

  private

  def attach(filename, content_type)
    file = Rack::Test::UploadedFile.new(file_fixture(filename), content_type)
    @assistant.documents.create!(file: file)
  end
end
