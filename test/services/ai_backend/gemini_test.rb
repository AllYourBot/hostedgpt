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

    history = conversation.messages.ordered.to_a[0...-1]
    newest_user_message = history.select(&:user?).last

    history.zip(preceding_conversation_messages).each do |message, sent|
      if message.documents.present?
        time_note = message == newest_user_message ? 1 : 0
        assert_instance_of Array, sent[:parts]
        assert_equal message.documents.length + 1 + time_note, sent[:parts].length
      else
        assert_equal message.content_text || "", sent[:parts][:text]
      end
    end
  end

  test "preceding_conversation_messages attaches the assistant's context images to the first user message only" do
    @assistant.language_model.update!(supports_images: true)
    @assistant.documents.create!(file: fixture_file_upload("cat.png", "image/png"))

    first_user, _reply, newest_user = @gemini.send(:preceding_conversation_messages)

    assert_equal({ text: "Hi Claude, can you hear me?" }, first_user[:parts].first, "The user's own text should come first")
    assert_equal "image/png", first_user[:parts].second.dig(:inline_data, :mime_type), "The context image should ride on the first user message"
    refute newest_user[:parts].any? { |part| part[:inline_data] }, "The context image should not be repeated on later messages"
  end

  test "preceding_conversation_messages sends a PDF as inline data when the model supports PDFs" do
    @assistant.language_model.update!(supports_pdf: true)

    parts = backend_replying_to_pdf("quarterly.pdf", file_fixture("quarterly.pdf").binread).send(:preceding_conversation_messages).first[:parts]

    assert_includes parts, { inline_data: { mime_type: "application/pdf", data: Base64.strict_encode64(file_fixture("quarterly.pdf").binread) } }
  end

  test "preceding_conversation_messages sends a PDF's text to a model without PDF or image support" do
    @assistant.language_model.update!(supports_pdf: false, supports_images: false)

    parts = backend_replying_to_pdf("quarterly.pdf", file_fixture("quarterly.pdf").binread).send(:preceding_conversation_messages).first[:parts]

    assert_includes parts, { text: "[PDF Document: quarterly.pdf]\nQuarterly numbers" }
  end

  test "preceding_conversation_messages says so when a PDF's text cannot be extracted" do
    @assistant.language_model.update!(supports_pdf: false)

    parts = backend_replying_to_pdf("corrupted.pdf", "%PDF-1.4\ncorrupted content").send(:preceding_conversation_messages).first[:parts]

    assert_includes parts, { text: "[PDF Document: corrupted.pdf - Unable to extract text from this PDF]" }
  end

  test "preceding_conversation_messages puts the current time on the newest user message only" do
    first_user, _reply, newest_user = @gemini.stub(:current_time_note, "NOTE") { @gemini.send(:preceding_conversation_messages) }

    assert_equal({ text: "Hi Claude, can you hear me?" }, first_user[:parts])
    assert_equal [{ text: "How old are you?" }, { text: "NOTE" }], newest_user[:parts]
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

  def backend_replying_to_pdf(filename, pdf_bytes)
    conversation = Conversation.create!(user: users(:keith), assistant: @assistant, title: "PDF Test Conversation")
    message = conversation.messages.create!(role: "user", content_text: "Please analyze this PDF", assistant: @assistant)
    message.documents.create!(file: { io: StringIO.new(pdf_bytes), filename:, content_type: "application/pdf" })
    reply = conversation.messages.create!(role: "assistant", content_text: "I'll analyze the PDF for you", assistant: @assistant)

    AIBackend::Gemini.new(users(:keith), @assistant, conversation, reply)
  end

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
