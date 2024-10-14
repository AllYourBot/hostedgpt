class SendResetPasswordEmailJob < ApplicationJob
  queue_as :default

  def perform(email, os, browser)
    person = Person.find_by_email(email)

    Rails.logger.level = 0

    Rails.logger.info "Sending reset password email to #{email} from #{os} with #{browser}"
    Rails.logger.error "-----------test error log"

    if person&.user # make sure the user exists (i.e. user has not become a tombstone)
      PasswordMailer.with(person: person, os: os, browser: browser).reset.deliver_now
    end
  end
end
