require "test_helper"

class GeneratedImageTest < ActiveSupport::TestCase
  # 1x1 red PNG
  BASE64_PNG = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=="

  setup do
    @message = messages(:image_generation_tool_call)
  end

  test "attach_to! attaches the decoded PNG to the message as an assistants_output document" do
    assert_difference -> { @message.documents.count }, 1 do
      GeneratedImage.new(BASE64_PNG).attach_to!(@message)
    end

    document = @message.documents.reload.last
    assert_equal "generated.png", document.filename
    assert_equal "image/png", document.file.content_type
    assert_equal :assistants_output, document.purpose.to_sym
    assert_equal @message.assistant, document.assistant
    assert_equal @message.user, document.user
    assert document.has_image?
  end

  test "attach_to! skips blank or nil payloads without touching the message" do
    assert_no_difference -> { @message.documents.count } do
      GeneratedImage.new(nil).attach_to!(@message)
      GeneratedImage.new("").attach_to!(@message)
    end
  end

  test "attach_to! leaves no document behind on failure" do
    Tempfile.stub :new, nil do
      assert_no_difference -> { @message.documents.count } do
        assert_raises(NoMethodError) do
          GeneratedImage.new(BASE64_PNG).attach_to!(@message)
        end
      end
    end
  end
end
