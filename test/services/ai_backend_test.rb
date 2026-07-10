require "test_helper"

class AIBackendTest < ActiveSupport::TestCase
  include ActionDispatch::TestProcess::FixtureFile

  setup do
    TestChat.reset
    @conversation = conversations(:attachments)
    @assistant = assistants(:keith_gpt4)
    @assistant.language_model.update!(supports_tools: false)
    @backend = AIBackend.new(
      users(:keith),
      @assistant,
      @conversation,
      @conversation.latest_message_for_version(:latest)
    )
  end

  test "initializing chat works" do
    assert @backend.send(:build_chat).present?
  end

  test "get_oneoff_message responds with a reply" do
    TestChat.text = "Yes, I can hear you."
    response = @backend.get_oneoff_message("I am a helpful assistant.", ["Can you hear me?"])
    assert_equal "Yes, I can hear you.", response
  end

  test "get_oneoff_message with response_format of json returns a hash" do
    TestChat.text = "{\"response\":\"yes\"}"
    response = @backend.get_oneoff_message("Reply with the JSON { response: 'yes' }", ["Give me the reply."], response_format: { type: "json_object" })
    assert_equal({"response"=>"yes"}, JSON.parse(response))
  end

  test "stream_next_conversation_message works to stream text and uses model from assistant" do
    assert_not_equal @assistant, @conversation.assistant, "Should force this next message to use a different assistant so these don't match"

    TestChat.text = nil
    streamed_text = ""
    @backend.stream_next_conversation_message { |chunk| streamed_text += chunk }
    expected_start = "Hello this is model gpt-4o with instruction"
    expected_end = "! How can I assist you today?"
    assert streamed_text.start_with?(expected_start)
    assert streamed_text.end_with?(expected_end)
  end

  test "get_tool_messages_by_calling properly executes tools" do
    tool_message = {
      role: "tool",
      content: "\"Hello, World!\"",
      tool_call_id: "abc123",
      content_tool_calls: messages(:weather_tool_call).content_tool_calls.first,
    }
    assert_equal [tool_message], AIBackend.get_tool_messages_by_calling(messages(:weather_tool_call).content_tool_calls)
  end

  test "get_tool_messages_by_calling gracefully handles a failure within a function call" do
    tool_calls = messages(:weather_tool_call).content_tool_calls
    tool_calls[0][:function][:name] = "helloworld_bad"
    tool_calls[0][:function][:arguments].delete(:name)

    msg = AIBackend.get_tool_messages_by_calling(tool_calls).first
    assert_equal "tool", msg[:role]
    assert_equal "abc123", msg[:tool_call_id]
    assert msg[:content].starts_with?('"An unexpected error occurred')
  end

  test "get_tool_messages_by_calling gracefully handles calling an invalid function" do
    tool_calls = messages(:weather_tool_call).content_tool_calls
    tool_calls[0][:function][:name] = "helloworld_nonexistent"
    tool_calls[0][:function][:arguments].delete(:name)

    msg = AIBackend.get_tool_messages_by_calling(tool_calls).first
    assert_equal "tool", msg[:role]
    assert_equal "abc123", msg[:tool_call_id]
    assert msg[:content].starts_with?('"An unexpected error occurred')
  end

  test "tools only passed when supported by the language model" do
    @assistant.language_model.update!(supports_tools: true)
    function = "openmeteo_get_current_and_todays_weather"
    streamed_text = ""

    TestChat.function = function
    @backend.stream_next_conversation_message { |chunk| streamed_text += chunk }
  end

  test "tools not passed when not supported by the language model" do
    streamed_text = ""

    TestChat.text = nil
    @backend.stream_next_conversation_message { |chunk| streamed_text += chunk }
  end

  test "stream_next_conversation_message works to get a function call" do
    @assistant.language_model.update!(supports_tools: true)
    function = "openmeteo_get_current_and_todays_weather"

    TestChat.function = function
    streamed_text = ""
    function_call = @backend.stream_next_conversation_message { |chunk| streamed_text += chunk }
    assert_equal function, function_call.dig(0, :function, :name)
  end

  test "stream_next_conversation_message works to get a parallel function call" do
    @assistant.language_model.update!(supports_tools: true)
    function = "openmeteo_get_current_and_todays_weather"

    TestChat.function = function
    TestChat.num_tool_calls = 2
    streamed_text = ""
    function_calls = @backend.stream_next_conversation_message { |chunk| streamed_text += chunk }

    assert_equal 2, function_calls.length
    assert_equal [0, 1], function_calls.map { |f| f[:index] }
    assert_equal [function, function], function_calls.map { |f| f[:function][:name] }
  end

  test "preceding_conversation_messages constructs a proper response and pivots on images" do
    preceding = @backend.send(:preceding_conversation_messages)

    assert_equal @conversation.messages.length - 1, preceding.length

    @conversation.messages.ordered.each_with_index do |message, i|
      next if @conversation.messages.length == i + 1

      if message.documents.present?
        assert_instance_of RubyLLM::Content::Raw, preceding[i][:content]
      else
        assert_equal preceding[i][:content], message.content_text
      end
    end
  end

  test "preceding_conversation_messages only considers messages on the intended conversation version and includes the correct names" do
    message = messages(:message3_v1)
    conversation = message.conversation
    assistant = message.assistant
    user = message.user
    version = message.version
    @backend = AIBackend.new(user, assistant, conversation, message)

    preceding = @backend.send(:preceding_conversation_messages)
    convo_messages = conversation.messages.for_conversation_version(version).where("messages.index < ?", message.index)

    assert_equal convo_messages.map(&:content_text), preceding.map { |m| m[:content] }
  end

  test "preceding_conversation_messages includes the appropriate tool details" do
    message = messages(:weather_explained)
    conversation = message.conversation
    assistant = message.assistant
    user = message.user
    version = message.version
    @backend = AIBackend.new(user, assistant, conversation, message)

    msgs = @backend.send(:preceding_conversation_messages)

    m1 = { role: :user, content: "What is the weather in Austin?" }
    assert_equal m1, msgs.first

    m2 = msgs.second
    assert_equal :assistant, m2[:role]
    assert m2[:tool_calls].present?, "Assistant message should have tool_calls"
  end

  test "preceding_conversation_messages processes PDF documents" do
    assistant = assistants(:keith_claude35)
    assistant.language_model.update!(supports_pdf: true)

    conversation = Conversation.create!(user: users(:keith), assistant: assistant, title: "PDF Test Conversation")

    pdf_content = "%PDF-1.4\n1 0 obj\n<<\n/Type /Catalog\n/Pages 2 0 R\n>>\nendobj\n2 0 obj\n<<\n/Type /Pages\n/Kids [3 0 R]\n/Count 1\n>>\nendobj\n3 0 obj\n<<\n/Type /Page\n/Parent 2 0 R\n/MediaBox [0 0 612 792]\n/Contents 4 0 R\n>>\nendobj\n4 0 obj\n<<\n/Length 44\n>>\nstream\nBT\n/F1 12 Tf\n72 720 Td\n(Hello World) Tj\nET\nendstream\nendobj\nxref\n0 5\n0000000000 65535 f \n0000000009 00000 n \n0000000058 00000 n \n0000000115 00000 n \n0000000200 00000 n \ntrailer\n<<\n/Size 5\n/Root 1 0 R\n>>\nstartxref\n294\n%%EOF"

    test_file = Tempfile.new(["test", ".pdf"])
    test_file.write(pdf_content)
    test_file.rewind

    message = conversation.messages.create!(role: "user", content_text: "Please analyze this PDF", assistant: assistant)
    message.documents.create!(file: fixture_file_upload(test_file.path, "application/pdf"), filename: "test.pdf")

    second_message = conversation.messages.create!(role: "assistant", content_text: "I'll analyze the PDF for you", assistant: assistant)

    backend = AIBackend.new(users(:keith), assistant, conversation, second_message)
    msgs = backend.send(:preceding_conversation_messages)

    pdf_message = msgs.find { |m| m[:content].is_a?(RubyLLM::Content::Raw) }
    assert pdf_message, "Should find a message with raw content (PDF)"
    assert_equal :user, pdf_message[:role]

    test_file.close
    test_file.unlink
  end

  test "preceding_conversation_messages handles PDF extraction errors gracefully" do
    assistant = assistants(:keith_claude35)
    assistant.language_model.update!(supports_pdf: true)

    conversation = Conversation.create!(user: users(:keith), assistant: assistant, title: "PDF Error Test Conversation")

    test_file = Tempfile.new(["test", ".pdf"])
    test_file.write("%PDF-1.4\ncorrupted content")
    test_file.rewind

    message = conversation.messages.create!(role: "user", content_text: "Please analyze this PDF", assistant: assistant)
    message.documents.create!(file: fixture_file_upload(test_file.path, "application/pdf"), filename: "corrupted.pdf")

    second_message = conversation.messages.create!(role: "assistant", content_text: "I'll try to analyze the PDF for you", assistant: assistant)

    backend = AIBackend.new(users(:keith), assistant, conversation, second_message)
    msgs = backend.send(:preceding_conversation_messages)

    pdf_message = msgs.find { |m| m[:content].is_a?(RubyLLM::Content::Raw) }
    assert pdf_message, "Should find a message with raw content (PDF)"
    assert_equal :user, pdf_message[:role]

    test_file.close
    test_file.unlink
  end
end
