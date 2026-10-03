class PasswordsMailer < ApplicationMailer
  default from: -> { email_address_with_name(admin_address, blog_title) }

  def reset(author)
    @author = author
    mail(
      subject: "Reset your password",
      to: author.email_address
    )
  end

  private
    def admin_address
      blog_email_address("admin")
    end
end
