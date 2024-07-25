require "postmark-rails/templated_mailer"

class PasswordMailer < PostmarkRails::TemplatedMailer
  def reset
    person = params[:person]
    user = person.user

    ttl_minutes = Rails.application.config.password_reset_token_ttl_minutes

    token = user.signed_id(
      purpose: Rails.application.config.password_reset_token_purpose,
      expires_in: ttl_minutes.minutes
    )
    change_password_url = edit_password_url(token: token)

    ttl_sentence = ActiveSupport::Duration.build(ttl_minutes * 60).as_sentence

    self.template_model = {
      product_url: Setting.action_mailer_host,
      product_name: Setting.product_name,
      name: user.first_name,
      token_ttl: ttl_sentence,
      action_url: change_password_url,
      operating_system: params[:os],
      browser_name: params[:browser],
    }

    mail(
      from: Setting.postmark_from_email,
      to: person.email,
      postmark_template_alias: Setting.postmark_password_reset_template_alias
    )
  end
end
