class Toolbox::Gmail::Message
  def initialize(message_or_messages)
    if message_or_messages.is_a?(Array)
      message_or_messages.map { Message.new(it) }
    else
      @message = message_or_messages
    end
  end

  def id = @message.id

  def thread_id = @message.threadId

  def from = header("From")

  def from_email = from&.match?(/\A<([^>]*)>/) ? $1 : from

  def to = header("To")

  def to_email = to&.match?(/\A<([^>]*)>/) ? $1 : to

  def subject = header("Subject")

  def snippet = @message.snippet

  def date = header("Date")

  def body = decoded_part("text/plain")

  def body_html = decoded_part("text/html")

  def to_h
    {
      id:,
      thread_id:,
      date:,
      from:,
      to:,
      subject:,
      snippet:,
      body: body || body_html,
    }
  end

  def data = @message

  def inspect = "#<Message id:#{id} from:#{from_email} to:#{to_email} subject:#{subject}>"

  private

  def header(name) = @message.payload.headers.find { it.name.casecmp?(name) }&.value

  def decoded_part(mime_type)
    data = find_part(@message.payload, mime_type)&.body&.try(:data)
    data && Base64.urlsafe_decode64(data).force_encoding(Encoding::UTF_8).scrub
  end

  # A single-part message keeps its body on the payload itself, and one with attachments
  # nests the text a level down inside multipart/alternative, so search the whole tree.
  def find_part(part, mime_type)
    return part if part.mimeType == mime_type

    part.try(:parts)&.each do |child|
      found = find_part(child, mime_type)
      return found if found
    end
    nil
  end
end
