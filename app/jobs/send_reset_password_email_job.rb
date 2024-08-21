class SendResetPasswordEmailJob < ApplicationJob
  queue_as :default

  def perform(email, os, browser)
    person = Person.find_by_email(email)

    if person&.user # make sure the user exists (i.e. user has not become a tombstone)
      PasswordMailer.with(person: person, os: os, browser: browser).reset.deliver_now
    end
  end
end
