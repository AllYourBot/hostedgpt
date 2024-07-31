class PasswordMailer < ApplicationMailer
  def reset
    person = params[:person]
    @user = person.user
    @os = params[:os]
    @browser = params[:browser]

    @token_ttl = Rails.application.config.password_reset_token_ttl

    token = @user.signed_id(
      purpose: Rails.application.config.password_reset_token_purpose,
      expires_in: @token_ttl
    )
    @edit_url = edit_password_credential_url(token: token)

    mail(
      to: person.email,
      subject: "Set up a new password for #{Setting.product_name}",
    )
  end
end
