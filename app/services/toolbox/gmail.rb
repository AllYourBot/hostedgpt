class Toolbox::Gmail < Toolbox
  include GoogleApp

  describe :email_myself, <<~S
    Send an email to yourself with the indicated message
  S

  def email_myself(message_s:)
    subject = message_s
    if message_s.length > 60
      subject = "Note to self"
      body = message_s
    end
    to = Current.user.gmail_credential.oauth_email

    draft = create_draft(to: to, subject: subject, body: body)
    raise "Could not send message for an unknown reason." if !draft&.id
    send_draft(draft.id)
    # message_send(from: to, to: to, subject: subject, body: body)

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
    raise "Could not send message for an unknown reason." if !draft&.id
    send_draft(draft.id)

    "Email has been sent"
  end

  describe :check_inbox, <<~S
    Check the users gmail inbox to see how many messages are in there, how many are unread vs read, and what the
    latest message is.
  S

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

  private

  def get_user_profile
    refresh_token_if_needed do
      get("https://gmail.googleapis.com/gmail/v1/users/#{uid}/profile").no_params
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
  end

  def send_draft(draft_id)
    refresh_token_if_needed do
      post("https://gmail.googleapis.com/gmail/v1/users/#{uid}/drafts/send").param(
        id: draft_id
      )
    end
  end

  # TODO: We should be able to send a message direclty, without first creating a draft.
  # But I can't get this API call to work.
  #
  # def message_send(from:, to:, subject:, body:)
  #   message = <<~S
  #     From: #{from}
  #     To: #{to}
  #     Subject: #{subject}

  #     #{body}
  #   S

  #   encoded_message = Base64.urlsafe_encode64(message)

  #   refresh_token_if_needed do
  #     post("https://gmail.googleapis.com/gmail/v1/users/#{uid}/messages/send").param(
  #         message: {
  #           raw: encoded_message
  #         }
  #     )
  #   end
  # end

  def get_threads(h = {})
    refresh_token_if_needed do
      get("https://gmail.googleapis.com/gmail/v1/users/#{uid}/threads").param(h)
    end&.threads
  end

  def get_messages(h = {})
    refresh_token_if_needed do
      get("https://gmail.googleapis.com/gmail/v1/users/#{uid}/messages").param(h)
    end&.messages
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

  # These API calls work but we are not using them yet.
  #


  # def get_user_labels
  #   refresh_token_if_needed do
  #     get("https://gmail.googleapis.com/gmail/v1/users/#{uid}/labels").no_params
  #   end
  # end # .labels.last   # #<OpenStruct id="Label_8804082651400413034", name="F: international", messageListVisibility="show", labelListVisibility="labelHide", type="user">

  # def get_user_drafts
  #   # https://developers.google.com/gmail/api/reference/rest/v1/users.drafts/list
  #   refresh_token_if_needed do
  #     get("https://gmail.googleapis.com/gmail/v1/users/#{uid}/drafts").param(
  #       maxResults: 100,
  #       includeSpamTrash: false,
  #     )
  #   end
  # end # .drafts.first.id    # {:drafts=> [{:id=>"r2958353423951382939", :message=>{:id=>"18fc47b5ef586361", :threadId=>"18fbbf7381c4bc73"}},

  # def get_user_draft(id)
  #   refresh_token_if_needed do
  #     get("https://gmail.googleapis.com/gmail/v1/users/#{uid}/drafts/#{id}").param(
  #       format: :full
  #     )
  #   end
  # end

  def app_credential
    Current.user&.gmail_credential
  end
end
