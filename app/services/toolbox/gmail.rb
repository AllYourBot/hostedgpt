class Toolbox::Gmail < Toolbox

  describe :email_myself, <<~S
    Send an email to yourself with the indicated message
  S

  def email_myself(message_s:)
    subject = message_s
    if message_s.length > 60
      subject = "Note to self"
      body = message_s
    end
    to = Current.user.gmail_credential.email

    draft = create_draft(to: to, subject: subject, body: body)
    raise "Unable to create message" if !draft&.try(:id)
    send_draft(draft.id)  # TODO: Change to send_message https://developers.google.com/gmail/api/reference/rest/v1/users.messages/send

    "Email has been sent"
  end

  describe :send_email_to_address, <<~S
    Send an email message to any address. The email_address must be specified so if you were told the name of
    a person to email and you were not previously told the email address for that name then BE SURE TO ASK for this
    name's email address. Before you send any emails confirm the exact subject and message you are about to use so
    that you are certain the user is okay with you sending.
  S

  def send_email_to_address(email_address_s:, subject_s:, message_s:)
    draft = create_draft(
      to: email_address_s,
      subject: subject_s,
      body: message_s
    )
    raise "Unable to create message" if !draft&.id
    send_draft(draft.id)  # TODO: Change to send_message https://developers.google.com/gmail/api/reference/rest/v1/users.messages/send

    "Email has been sent"
  end

  def check_inbox
    inbox = get_threads(q: "in:inbox")
    unread_inbox = get_threads(q: "in:inbox is:unread")
    latest_message = get_message(:latest)
    latest_sent_message = get_message(:latest_sent)

    {
      messages_in_inbox: inbox.length,
      unread_messages_in_inbox: unread_inbox.length,
      read_messages_in_inbox: inbox.length - unread_inbox.length,
      most_recent_message: latest_message.to_h,
      last_sent_message: latest_sent_message.to_h,
    }
  end

  def check_sent_emails
    sent_emails = get_threads(q: "in:sent")
    {
      sent_emails: sent_emails.length,
    }
  end

  private

  def get_user_profile
    refresh_token_if_needed do
      get("https://gmail.googleapis.com/gmail/v1/users/#{uid}/profile").no_param
    end
  end # #<OpenStruct emailAddress="krschacht@gmail.com", messagesTotal=874908, threadsTotal=536434, historyId="73971375">

  def get_messages(h = {})
    refresh_token_if_needed do
      get("https://gmail.googleapis.com/gmail/v1/users/#{uid}/messages").param(h)
    end&.try(:messages)
  end

  def get_message(id)
    case id
    when :latest
      id = get_messages(q: "in:inbox", maxResults: 1).first.id
    when :latest_sent
      id = get_messages(q: "in:sent", maxResults: 1).first.id
    end

    data = refresh_token_if_needed do
      get("https://gmail.googleapis.com/gmail/v1/users/#{uid}/messages/#{id}").param(
        format: :full
      )
    end
    Message.new(data)
  end

  def get_threads(h = {})
    refresh_token_if_needed do
      get("https://gmail.googleapis.com/gmail/v1/users/#{uid}/threads").param(h)
    end&.try(:threads)
  end

  def get_user_labels
    refresh_token_if_needed do
      get("https://gmail.googleapis.com/gmail/v1/users/#{uid}/labels").no_param
    end
  end # .labels.last   # #<OpenStruct id="Label_8804082651400413034", name="F: international", messageListVisibility="show", labelListVisibility="labelHide", type="user">

  def get_user_drafts
    # https://developers.google.com/gmail/api/reference/rest/v1/users.drafts/list
    refresh_token_if_needed do
      get("https://gmail.googleapis.com/gmail/v1/users/#{uid}/drafts").param(
        maxResults: 100,
        includeSpamTrash: false,
      )
    end
  end # .drafts.first.id    # {:drafts=> [{:id=>"r2958353423951382939", :message=>{:id=>"18fc47b5ef586361", :threadId=>"18fbbf7381c4bc73"}},

  def get_user_draft(id)
    refresh_token_if_needed do
      get("https://gmail.googleapis.com/gmail/v1/users/#{uid}/drafts/#{id}").param(
        format: :full
      )
    end
  end

  def create_draft(to:, subject:, body:)
    message = <<~S
      From: krschacht@gmail.com
      To: #{to}
      Subject: #{subject}

      #{body}
    S

    encoded_message = Base64.urlsafe_encode64(message)

    refresh_token_if_needed do
      post("https://gmail.googleapis.com/gmail/v1/users/#{uid}/drafts").param(
          message: {
            raw: encoded_message
          }
      )
    end
  end # #<OpenStruct {:id: "r-5831085103476355142", :message: {:id: "18fc5c05dbc1932d", :threadId: "18fc5c05dbc1932d", :labelIds: ["DRAFT"]}}>

  def send_draft(draft_id)
    refresh_token_if_needed do
      post("https://gmail.googleapis.com/gmail/v1/users/#{uid}/drafts/send").param(
        id: draft_id
      )
    end
  end # #<OpenStruct {:id: "18fc5cb7c7c88199", :threadId: "18fc5c05dbc1932d", :labelIds: ["CATEGORY_PERSONAL", "SENT"]}>


  # Utilities

  def refresh_token_if_needed(&block)
    2.times do |i|
      response = yield block
      expired_token = response.is_a?(Faraday::Response) && response.status == 401

      refresh_token! && next if i == 0 && expired_token
      return response
    end
  end

  def refresh_token!
    if !Google.reauthenticate_credential(Current.user.gmail_credential)
      raise "Gmail no longer connected"
    else
      true
    end
  end

  def uid
    Current.user&.auth_uid
  end

  def bearer_token
    token = Current.user&.gmail_credential&.reload&.active_authentication&.token
    raise "Unable to find a user with Gmail credentials" unless token
    token
  end

  def header
    { content_type: "application/json" }
  end

  def expected_status
    [200, 401]
  end

  class Message
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
      @message.thread_id
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
      Base64.decode64(@message.payload.parts.find { |p| p.mimeType == "text/plain" }.body.data.gsub(/-/, '+').gsub(/_/, '/'))
    end

    def body_html
      Base64.decode64(@message.payload.parts.find { |p| p.mimeType == "text/html" }.body.data.gsub(/-/, '+').gsub(/_/, '/'))
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
        body: body,
      }
    end

    def data
      @message
    end

    def inspect
      "#<Message id:#{id} from:#{from_email} to:#{to_email} subject:#{subject}>"
    end
  end
end
