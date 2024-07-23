class SendResetPasswordEmailJob < ApplicationJob
  queue_as :default

  def perform(email, user_agent)
    os = get_os_from_user_agent(user_agent)
    browser = get_browser_from_user_agent(user_agent)

    if @person = Person.find_by_email(email)
      PasswordMailer.with(person: @person, os: os, browser: browser).reset.deliver_later
    end
  end

  private

  def get_os_from_user_agent(user_agent)
    if user_agent.include?("Windows")
      "Windows"
    elsif user_agent.include?("Macintosh")
      "Macintosh"
    elsif user_agent.include?("Linux")
      "Linux"
    elsif user_agent.include?("Android")
      "Android"
    elsif user_agent.include?("iPhone")
      "iPhone"
    else
      "unknown operating system"
    end
  end

  def get_browser_from_user_agent(user_agent)
    if user_agent.include?("Chrome")
      "Chrome"
    elsif user_agent.include?("Safari")
      "Safari"
    elsif user_agent.include?("Firefox")
      "Firefox"
    elsif user_agent.include?("Edge")
      "Edge"
    elsif user_agent.include?("Opera")
      "Opera"
    else
      "unknown browser"
    end
  end
end
