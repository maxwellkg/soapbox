# Preview all emails at http://localhost:3000/rails/mailers/post_emails_mailer
class PostEmailsMailerPreview < ActionMailer::Preview
  def post_email
    PostEmailsMailer
      .with(post_email: PostEmail.take)
      .post_email
  end
end
