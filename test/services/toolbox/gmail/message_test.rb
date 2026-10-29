require "test_helper"

class Toolbox::Gmail::MessageTest < ActiveSupport::TestCase
  test "body reads a SINGLE-PART message, which keeps its text on the payload" do
    message = gmail_message(payload: text_part("text/plain", "Your order has shipped."))

    assert_equal "Your order has shipped.", message.body, "The text should be read from the payload"
    assert_equal "Your order has shipped.", message.to_h[:body], "to_h should include the body"
  end

  test "body reads a MULTIPART message" do
    message = gmail_message(payload: {
      mimeType: "multipart/alternative",
      headers:,
      body: { size: 0 },
      parts: [ text_part("text/plain", "Plain text"), text_part("text/html", "<p>HTML</p>") ],
    })

    assert_equal "Plain text", message.body, "The text/plain part should be the body"
    assert_equal "<p>HTML</p>", message.body_html, "The text/html part should be the html body"
  end

  test "body reads the text NESTED inside a message with an attachment" do
    message = gmail_message(payload: {
      mimeType: "multipart/mixed",
      headers:,
      body: { size: 0 },
      parts: [
        {
          mimeType: "multipart/alternative",
          body: { size: 0 },
          parts: [ text_part("text/plain", "See the attached invoice"), text_part("text/html", "<p>See the attached invoice</p>") ],
        },
        { mimeType: "application/pdf", filename: "invoice.pdf", body: { attachmentId: "ANGjdJ8", size: 52_431 } },
      ],
    })

    assert_equal "See the attached invoice", message.body, "The text inside multipart/alternative should be found"
  end

  test "to_h falls back to the html body when there is NO plain text" do
    message = gmail_message(payload: text_part("text/html", "<p>Your receipt</p>"))

    assert_nil message.body, "There is no text/plain part"
    assert_equal "<p>Your receipt</p>", message.to_h[:body], "to_h should use the html body instead"
  end

  test "body is UTF-8 so the message can be sent back to the assistant as JSON" do
    message = gmail_message(payload: text_part("text/plain", "Café at 3 — see you"))

    assert_equal Encoding::UTF_8, message.body.encoding, "The decoded body should not be left as binary"
    assert_equal "Café at 3 — see you", JSON.parse(message.to_h.to_json)["body"], "The body should survive a JSON round trip"
  end

  test "headers are nil when the message DOES NOT HAVE them" do
    bcc_only_headers = headers.reject { |h| h[:name] == "To" }
    message = gmail_message(payload: text_part("text/plain", "Sent to an undisclosed list").merge(headers: bcc_only_headers))

    assert_nil message.to, "A message sent only to Bcc recipients has no To header"
    assert_nil message.to_email, "to_email should not raise without a To header"
    assert_equal "Weekly update", message.to_h[:subject], "The other headers should still be read"
  end

  private

  def gmail_message(payload:)
    Toolbox::Gmail::Message.new(OpenData.new(id: "18fc47b5ef586361", threadId: "18fbbf7381c4bc73", snippet: "A snippet", payload: { headers: }.merge(payload)))
  end

  def text_part(mime_type, text)
    { mimeType: mime_type, body: { size: text.bytesize, data: Base64.urlsafe_encode64(text, padding: false) } }
  end

  def headers
    [
      { name: "From", value: "Keith Schacht <keith@example.com>" },
      { name: "To", value: "rob@example.com" },
      { name: "Subject", value: "Weekly update" },
      { name: "Date", value: "Tue, 27 Oct 2026 09:14:02 -0500" },
    ]
  end
end
