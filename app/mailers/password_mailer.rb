require 'postmark-rails/templated_mailer'

class PasswordMailer < PostmarkRails::TemplatedMailer
  def reset
    person = params[:person]

    @token = person.signed_id(
      purpose: Rails.application.config.password_reset_token_purpose,
      expires_in: Rails.application.config.password_reset_token_ttl_minutes.minutes
    )
    token_url = password_reset_edit_url(token: @token)

    user = person.personable

    ttl_minutes = Rails.application.config.password_reset_token_ttl_minutes
    ttl_sentence = ActiveSupport::Duration.build(ttl_minutes * 60).as_sentence

    self.template_model = {
      product_url: Setting.action_mailer_host,
      product_name: Setting.product_name,
      name: user.first_name,
      token_ttl: ttl_sentence,
      action_url: token_url,
      operating_system: params[:os],
      browser_name: params[:browser],
      support_url: Setting.support_url,
      company_name: Setting.company_name,
      company_address: Setting.company_address
    }

    mail(
      from: Setting.postmark_from_email,
      to: person.email,
      postmark_template_alias: Setting.postmark_password_reset_template_alias
    )
  end
end
