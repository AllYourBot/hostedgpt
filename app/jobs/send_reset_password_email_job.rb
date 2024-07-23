class SendResetPasswordEmailJob < ApplicationJob
  queue_as :default

  def perform(email, user_agent)
    os = get_item_in_str(user_agent, KNOWN_OPERATING_SYSTEMS) || "unknown operating system"
    browser = get_item_in_str(user_agent, KNOWN_BROWSERS) || "unknown browser"

    if @person = Person.find_by_email(email)
      PasswordMailer.with(person: @person, os: os, browser: browser).reset.deliver_later
    end
  end

  private

  def get_item_in_str(str, items)
    items.each do |item|
      if str.include?(item)
        return item
      end
    end
  end
end
