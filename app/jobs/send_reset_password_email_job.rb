class SendResetPasswordEmailJob < ApplicationJob
  queue_as :default

  def perform(email, os, browser)
    person = Person.find_by_email(email)

    if person&.user&.password_credential
      PasswordMailer.with(person: person, os: os, browser: browser).reset.deliver_later
    end
  end
end
