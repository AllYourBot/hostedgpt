require 'postmark-rails/templated_mailer'

class PasswordMailer < PostmarkRails::TemplatedMailer
  def reset
    person = params[:person]
    os = params[:os]
    browser = params[:browser]

    @token = person.signed_id(
      purpose: Rails.application.config.password_reset_token_purpose,
      expires_in: Rails.application.config.password_reset_token_ttl_minutes.minutes
    )
    token_url = password_reset_edit_url(token: @token)

    user = person.personable

    self.template_model = {
      product_url: Setting.action_mailer_host,
      product_name: Setting.product_name,
      name: user.first_name,
      token_ttl: ttl_minutes_as_human_readable,
      action_url: token_url,
      operating_system: os,
      browser_name: browser,
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

  private

  def ttl_minutes_as_human_readable
    ttl_minutes = Rails.application.config.password_reset_token_ttl_minutes
    duration = ActiveSupport::Duration.build(ttl_minutes * 60)
    duration_as_sentence(duration)
  end

  def duration_as_sentence(duration)
    parts = duration.parts
    units = [:days, :hours, :minutes]
    map   = {
      :days     => { :one => :d, :other => :days },
      :hours    => { :one => :h, :other => :hours },
      :minutes  => { :one => :m, :other => :minutes }
    }

    parts.
      sort_by { |unit, _| units.index(unit) }.
      map     { |unit, val| "#{val} #{val == 1 ? map[unit][:one].to_s : map[unit][:other].to_s}" }.
      to_sentence
  end
end
