class ApplicationMailer < ActionMailer::Base
  default from: Setting.email_from
end
