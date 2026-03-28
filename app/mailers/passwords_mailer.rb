class PasswordsMailer < ApplicationMailer
  def reset(author)
    @author = author
    mail subject: "Reset your password", to: author.email_address
  end
end
