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

  private

  def get_user_profile
    get("https://gmail.googleapis.com/gmail/v1/users/#{uid}/profile").no_params
  end # #<OpenStruct emailAddress="krschacht@gmail.com", messagesTotal=874908, threadsTotal=536434, historyId="73971375">

  def get_user_labels
    get("https://gmail.googleapis.com/gmail/v1/users/#{uid}/labels").no_params
  end # .labels.last   # #<OpenStruct id="Label_8804082651400413034", name="F: international", messageListVisibility="show", labelListVisibility="labelHide", type="user">

  def get_user_drafts
    # https://developers.google.com/gmail/api/reference/rest/v1/users.drafts/list
    get("https://gmail.googleapis.com/gmail/v1/users/#{uid}/drafts").param(
      maxResults: 100,
      includeSpamTrash: false,
    )
  end # .drafts.first.id    # {:drafts=> [{:id=>"r2958353423951382939", :message=>{:id=>"18fc47b5ef586361", :threadId=>"18fbbf7381c4bc73"}},

  def get_user_draft(id)
    get("https://gmail.googleapis.com/gmail/v1/users/#{uid}/drafts/#{id}").param(
      format: :full
    )
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
      post("https://gmail.googleapis.com/gmail/v1/users/#{uid}/drafts").header(
        content_type: "application/json",
      ).expected_status([200, 401]
      ).param(
        message: {
          raw: encoded_message
        }
      )
    end
  end # #<OpenStruct {:id: "r-5831085103476355142", :message: {:id: "18fc5c05dbc1932d", :threadId: "18fc5c05dbc1932d", :labelIds: ["DRAFT"]}}>

  def send_draft(draft_id)
    refresh_token_if_needed do
      post("https://gmail.googleapis.com/gmail/v1/users/#{uid}/drafts/send").header(
        content_type: "application/json",
      ).expected_status([200, 401]
      ).param(
        id: draft_id
      )
    end
  end # #<OpenStruct {:id: "18fc5cb7c7c88199", :threadId: "18fc5c05dbc1932d", :labelIds: ["CATEGORY_PERSONAL", "SENT"]}>


  # Utilities

  def refresh_token_if_needed(&block)
    2.times do |i|
      response = yield block
      expired_token = response.is_a?(Faraday::Response) && response.status == 401

      refresh_token && next if i == 0 && expired_token
      return response
    end
  end

  def refresh_token
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
end
