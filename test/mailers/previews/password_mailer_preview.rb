# Preview all emails at http://localhost:3000/rails/mailers/password_mailer
class PasswordMailerPreview < ActionMailer::Preview

  # Preview this email at http://localhost:3000/rails/mailers/password_mailer/reset
  def reset
    user = User.first
    os = "Linux"
    browser = "Chrome"
    PasswordMailer.with(person: user.person, os: os, browser: browser).reset
  end
end
