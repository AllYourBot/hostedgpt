class Toolbox::Gmail::Message
  def initialize(message_or_messages)
    if message_or_messages.is_a?(Array)
      message_or_messages.map { |m| Message.new(m) }
    else
      @message = message_or_messages
    end
  end

  def id
    @message.id
  end

  def thread_id
    @message.threadId
  end

  def from
    @message.payload.headers.find { |h| h.name == "From" }.value
  end

  def from_email
    from.match?(/\A<([^>]*)>/) ? $1 : from
  end

  def to
    @message.payload.headers.find { |h| h.name == "To" }.value
  end

  def to_email
    to.match?(/\A<([^>]*)>/) ? $1 : to
  end

  def subject
    @message.payload.headers.find { |h| h.name == "Subject" }.value
  end

  def snippet
    @message.snippet
  end

  def date
    @message.payload.headers.find { |h| h.name == "Date" }.value
  end

  def body
    str = @message.payload.parts.find { |p| p.mimeType == "text/plain" }&.body&.data&.gsub(/-/, '+')&.gsub(/_/, '/')
    str && Base64.decode64(str)
  end

  def body_html
    str = @message.payload.parts.find { |p| p.mimeType == "text/html" }&.body&.data&.gsub(/-/, '+')&.gsub(/_/, '/')
    str && Base64.decode64(str)
  end

  def to_h
    {
      id: id,
      thread_id: thread_id,
      date: date,
      from: from,
      to: to,
      subject: subject,
      snippet: snippet,
      body: body || body_html,
    }
  end

  def data
    @message
  end

  def inspect
    "#<Message id:#{id} from:#{from_email} to:#{to_email} subject:#{subject}>"
  end
end
