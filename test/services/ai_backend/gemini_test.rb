require "test_helper"

class AIBackend::GeminiTest < ActiveSupport::TestCase
  include ActionDispatch::TestProcess::FixtureFile
  setup do
    @conversation = conversations(:hello_claude)
    @assistant = assistants(:keith_claude35)
    @assistant.language_model.update!(supports_tools: false)
    @gemini = AIBackend::Gemini.new(
      users(:keith),
      @assistant,
      @conversation,
      @conversation.latest_message_for_version(:latest)
    )
    TestClient::Gemini.new(access_token: "abc")
    TestClient::Gemini.reset_recordings!
  end

  test "one-off get_oneoff_message with json intent requests the json mime type" do
    TestClient::Gemini.stub :text, "{\"topic\":\"Gemini Tips\"}" do
      payload = @gemini.get_oneoff_message("Extract a topic.", ["Here is chat text."], json: true)

      assert_equal({ response_mime_type: "application/json" }, TestClient::Gemini.payload[:generation_config])
      assert_equal({ role: "user", parts: { text: "Here is chat text." } }, TestClient::Gemini.payload[:contents])
      assert_equal "Gemini Tips", JSON.parse(payload)["topic"]
    end
  end

  test "one-off get_oneoff_message without json intent omits generation_config" do
    @gemini.get_oneoff_message("plain", ["text"])

    assert_equal [ :system_instruction, :contents ], TestClient::Gemini.payload.keys
    refute TestClient::Gemini.payload.key?(:generation_config)
  end

  test "explicit caller generation_config still wins over json intent" do
    TestClient::Gemini.stub :text, "{}" do
      @gemini.get_oneoff_message(
        "Try to get JSON.",
        ["some text"],
        { generation_config: { response_mime_type: "text/plain" } },
        json: true
      )

      assert_equal({ response_mime_type: "text/plain" }, TestClient::Gemini.payload[:generation_config])
    end
  end

  test "one-off get_oneoff_message with json intent through a safety-blocked reply returns nil" do
    TestClient::Gemini.blocked = true

    assert_nil @gemini.get_oneoff_message("Extract a topic.", ["chat text"], json: true)
  ensure
    TestClient::Gemini.blocked = false
  end

  test "one-off generate_content records its payload and answers a candidates-shaped hash" do
    client = TestClient::Gemini.new({})
    payload = { contents: { role: "user", parts: { text: "Hello!" } }, system_instruction: "be terse" }

    response = client.generate_content(payload)

    assert_equal payload, TestClient::Gemini.payload
    assert response.dig("candidates", 0, "content", "parts", 0, "text").present?
  end

  test "generate_content honors a safety-block toggle and stays dig-safe" do
    TestClient::Gemini.blocked = true

    response = TestClient::Gemini.new({}).generate_content({ contents: {} })

    assert_nil response.dig("candidates", 0, "content", "parts", 0, "text")
    assert_equal "SAFETY", response.dig("promptFeedback", "blockReason")
  ensure
    TestClient::Gemini.blocked = false
  end

  test "initializing client works" do
    assert @gemini.client.present?
  end

  test "preceding_conversation_messages constructs a proper response and pivots on images" do
    conversation = conversations(:attachments)
    assistant = assistants(:keith_claude35)
    assistant.language_model.update!(supports_tools: false, supports_images: true)
    gemini = AIBackend::Gemini.new(
      users(:keith),
      assistant,
      conversation,
      conversation.latest_message_for_version(:latest)
    )

    preceding_conversation_messages = gemini.send(:preceding_conversation_messages)

    assert_equal conversation.messages.length - 1, preceding_conversation_messages.length

    conversation.messages.ordered.each_with_index do |message, i|
      next if conversation.messages.length == i + 1

      if message.documents.present?
        assert_instance_of Array, preceding_conversation_messages[i][:parts]
        assert_equal message.documents.length + 1, preceding_conversation_messages[i][:parts].length
      else
        assert_equal message.content_text || "", preceding_conversation_messages[i][:parts][:text]
      end
    end
  end

  test "preceding_conversation_messages processes PDF documents" do
    # Create a new conversation with a message that has a PDF document
    assistant = assistants(:keith_claude35)
    assistant.language_model.update!(supports_pdf: true)

    conversation = Conversation.create!(
      user: users(:keith),
      assistant: assistant,
      title: "PDF Test Conversation"
    )

    # Create a simple PDF file for testing
    pdf_content = "%PDF-1.4\n1 0 obj\n<<\n/Type /Catalog\n/Pages 2 0 R\n>>\nendobj\n2 0 obj\n<<\n/Type /Pages\n/Kids [3 0 R]\n/Count 1\n>>\nendobj\n3 0 obj\n<<\n/Type /Page\n/Parent 2 0 R\n/MediaBox [0 0 612 792]\n/Contents 4 0 R\n>>\nendobj\n4 0 obj\n<<\n/Length 44\n>>\nstream\nBT\n/F1 12 Tf\n72 720 Td\n(Hello World) Tj\nET\nendstream\nendobj\nxref\n0 5\n0000000000 65535 f \n0000000009 00000 n \n0000000058 00000 n \n0000000115 00000 n \n0000000200 00000 n \ntrailer\n<<\n/Size 5\n/Root 1 0 R\n>>\nstartxref\n294\n%%EOF"

    # Create a temporary PDF file
    test_file = Tempfile.new(["test", ".pdf"])
    test_file.write(pdf_content)
    test_file.rewind

    # Create a message with PDF attachment
    message = conversation.messages.create!(
      role: "user",
      content_text: "Please analyze this PDF",
      assistant: assistant
    )

    # Attach the PDF file
    message.documents.create!(
      file: fixture_file_upload(test_file.path, "application/pdf"),
      filename: "test.pdf"
    )

    # Create a second message to test with
    second_message = conversation.messages.create!(
      role: "assistant",
      content_text: "I'll analyze the PDF for you",
      assistant: assistant
    )

    gemini = AIBackend::Gemini.new(users(:keith), assistant, conversation, second_message)
    messages = gemini.send(:preceding_conversation_messages)


    # Find the message with PDF content
    pdf_message = messages.find { |m| m[:parts].is_a?(Array) && m[:parts].any? { |p| p[:text]&.include?("PDF Document: test.pdf") } }

    assert pdf_message, "Should find a message with PDF content"
    assert_equal "user", pdf_message[:role]

    # Check that the PDF content was processed (either successfully or with error message)
    pdf_content_part = pdf_message[:parts].find { |p| p[:text]&.include?("PDF Document: test.pdf") }
    assert pdf_content_part, "Should find PDF content part"
    # The PDF extraction might fail with our test PDF, so we check for either success or error message
    assert pdf_content_part[:text].include?("PDF Document: test.pdf"), "Should include PDF document reference"
    # Since our test PDF is not valid, we expect the error message
    assert pdf_content_part[:text].include?("Unable to extract text from this PDF"), "Should include error message for failed PDF extraction"

    test_file.close
    test_file.unlink
  end

  test "preceding_conversation_messages handles PDF extraction errors gracefully" do
    # Create a new conversation with a message that has a corrupted PDF document
    assistant = assistants(:keith_claude35)
    assistant.language_model.update!(supports_pdf: true)

    conversation = Conversation.create!(
      user: users(:keith),
      assistant: assistant,
      title: "PDF Error Test Conversation"
    )

    # Create a corrupted PDF file
    corrupted_pdf_content = "%PDF-1.4\ncorrupted content"

    # Create a temporary PDF file
    test_file = Tempfile.new(["test", ".pdf"])
    test_file.write(corrupted_pdf_content)
    test_file.rewind

    # Create a message with corrupted PDF attachment
    message = conversation.messages.create!(
      role: "user",
      content_text: "Please analyze this PDF",
      assistant: assistant
    )

    # Attach the corrupted PDF file
    message.documents.create!(
      file: fixture_file_upload(test_file.path, "application/pdf"),
      filename: "corrupted.pdf"
    )

    # Create a second message to test with
    second_message = conversation.messages.create!(
      role: "assistant",
      content_text: "I'll try to analyze the PDF for you",
      assistant: assistant
    )

    gemini = AIBackend::Gemini.new(users(:keith), assistant, conversation, second_message)
    messages = gemini.send(:preceding_conversation_messages)

    # Find the message with PDF content
    pdf_message = messages.find { |m| m[:parts].is_a?(Array) && m[:parts].any? { |p| p[:text]&.include?("PDF Document: corrupted.pdf") } }

    assert pdf_message, "Should find a message with PDF content"
    assert_equal "user", pdf_message[:role]

    # Check that the error message was included
    pdf_content_part = pdf_message[:parts].find { |p| p[:text]&.include?("PDF Document: corrupted.pdf") }
    assert pdf_content_part, "Should find PDF content part"
    assert_includes pdf_content_part[:text], "Unable to extract text from this PDF"

    test_file.close
    test_file.unlink
  end

  test "set_client_config only sends tools when the language model supports them" do
    gemini, assistant = gemini_for(conversations(:gemini_conversation))

    assistant.language_model.update!(supports_tools: false)
    gemini.send(:set_client_config, messages: [], instructions: "hi")
    assert_nil gemini.instance_variable_get(:@client_config)[:tools]

    assistant.language_model.update!(supports_tools: true)
    gemini.send(:set_client_config, messages: [], instructions: "hi")
    declarations = gemini.instance_variable_get(:@client_config).dig(:tools, 0, :function_declarations)
    assert declarations.present?, "Tools should have been declared for Gemini"
    assert_includes declarations.map { |d| d[:name] }, "helloworld_hi"
  end

  test "process_intermediate_response yields text chunks in order and accumulates them" do
    gemini, _assistant = gemini_for(conversations(:gemini_conversation))
    chunks = []

    ["Hello", " there", "!"].each do |text|
      gemini.instance_variable_set(:@stream_response_text, chunks.join)
      gemini.send(:process_intermediate_response, streamed_text(text)) { |chunk| chunks << chunk }
    end

    assert_equal ["Hello", " there", "!"], chunks
    assert_equal "Hello there!", gemini.instance_variable_get(:@stream_response_text)
  end

  test "process_intermediate_response collects function call parts instead of yielding them" do
    gemini, _assistant = gemini_for(conversations(:gemini_conversation))
    gemini.instance_variable_set(:@stream_response_text, "")
    gemini.instance_variable_set(:@stream_response_tool_calls, [])

    chunks = []
    gemini.send(:process_intermediate_response, streamed_function_call("helloworld_hi", { "name" => "Keith" })) { |chunk| chunks << chunk }

    assert_empty chunks
    assert_equal [{
      "functionCall" => { "name" => "helloworld_hi", "args" => { "name" => "Keith" } },
      "thoughtSignature" => "sig-abc"
    }], gemini.instance_variable_get(:@stream_response_tool_calls)
  end

  test "stream_next_conversation_message returns tool calls in the internal format" do
    conversation = conversations(:gemini_conversation)
    gemini, assistant = gemini_for(conversation)
    assistant.language_model.update!(supports_tools: true)

    response = TestClient::Gemini.stub :function, "helloworld_hi" do
      TestClient::Gemini.stub :arguments, { "name" => "Keith" } do
        gemini.stream_next_conversation_message { |chunk| }
      end
    end

    assert_equal 1, response.length
    assert_equal "helloworld_hi", response[0][:function][:name]
    assert_equal '{"name":"Keith"}', response[0][:function][:arguments]
  end

  test "preceding_conversation_messages converts tool calls and results into function parts" do
    conversation = conversations(:weather)
    gemini, _assistant = gemini_for(conversation)

    messages = gemini.send(:preceding_conversation_messages)

    tool_call = messages.find { |m| m[:parts].is_a?(Array) && m[:parts].any? { |p| p[:functionCall] } }
    assert_equal "model", tool_call[:role]
    assert_equal "helloworld_hi", tool_call[:parts][0][:functionCall][:name]
    assert_equal({ name: "World" }, tool_call[:parts][0][:functionCall][:args])

    tool_result = messages.find { |m| m[:parts].is_a?(Array) && m[:parts].any? { |p| p[:functionResponse] } }
    assert_equal "user", tool_result[:role], "Gemini has no tool role, so results come back from the user"
    assert_equal "helloworld_hi", tool_result[:parts][0][:functionResponse][:name]
    assert_equal "weather is", tool_result[:parts][0][:functionResponse][:response][:content]
  end

  test "preceding_conversation_messages replays the thoughtSignature Gemini issued with a tool call" do
    conversation = conversations(:weather)
    message = conversation.messages.ordered.find { |m| m.content_tool_calls.present? && m.assistant? }
    message.update!(content_tool_calls: message.content_tool_calls.map { |c| c.merge(thought_signature: "sig-abc") })

    gemini, _assistant = gemini_for(conversation)
    part = function_call_part_in(gemini.send(:preceding_conversation_messages))

    assert_equal "sig-abc", part[:thoughtSignature],
      "Gemini 3 rejects the follow-up request when a replayed functionCall has no signature"
  end

  test "preceding_conversation_messages omits thoughtSignature when the call never had one" do
    conversation = conversations(:weather)
    gemini, _assistant = gemini_for(conversation)

    part = function_call_part_in(gemini.send(:preceding_conversation_messages))

    refute part.key?(:thoughtSignature), "An empty signature should be left out rather than sent as null"
  end

  test "key_error_message returns the recorded Gemini copy" do
    assert_equal "(There is a configuration error with the Gemini API Service. Maybe you have an invalid API key? " +
      "Click your Profile in the bottom left and then Settings and then **API Services**. You will find Gemini there.)",
      AIBackend::Gemini.key_error_message
  end

  test "billing_url returns the recorded Gemini billing page" do
    assert_equal "https://aistudio.google.com/app/apikey", AIBackend::Gemini.billing_url
  end

  private

  def function_call_part_in(messages)
    messages.flat_map { |m| m[:parts].is_a?(Array) ? m[:parts] : [m[:parts]] }.find { |part| part[:functionCall] }
  end

  def gemini_for(conversation)
    assistant = assistants(:keith_gemini)
    gemini = AIBackend::Gemini.new(
      users(:keith),
      assistant,
      conversation,
      conversation.latest_message_for_version(:latest)
    )
    [gemini, assistant]
  end

  def streamed_text(text)
    { "candidates" => [{ "content" => { "role" => "model", "parts" => [{ "text" => text }] } }] }
  end

  def streamed_function_call(name, args)
    { "candidates" => [{ "content" => { "role" => "model",
      "parts" => [{ "functionCall" => { "name" => name, "args" => args }, "thoughtSignature" => "sig-abc" }] } }] }
  end
end
