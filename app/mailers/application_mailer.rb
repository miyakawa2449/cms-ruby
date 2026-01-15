class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAIL_FROM", "noreply@miyakawa.codes")
  layout "mailer"
end
