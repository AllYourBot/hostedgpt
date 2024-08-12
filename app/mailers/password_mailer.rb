class PasswordMailer < ApplicationMailer
  def reset
    person = params[:person]
    @user = person.user
    @os = params[:os]
    @browser = params[:browser]

    @token_ttl = Email::PasswordReset::TOKEN_TTL

    token = @user.signed_id(
      purpose: Email::PasswordReset::TOKEN_PURPOSE,
      expires_in: @token_ttl
    )
    @edit_url = edit_password_credential_url(token: token)

    mail(
      to: person.email,
      subject: "Set up a new password for #{Setting.product_name}",
    )
  end
end
