class SendResetPasswordEmailJob < ApplicationJob
  queue_as :default

  def perform(email, os, browser)
    if @person = Person.find_by_email(email)
      PasswordMailer.with(person: @person, os: os, browser: browser).reset.deliver_later
    end
  end
end
