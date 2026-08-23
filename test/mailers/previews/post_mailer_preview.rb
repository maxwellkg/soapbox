# Preview all emails at http://localhost:3000/rails/mailers/post_mailer
class PostMailerPreview < ActionMailer::Preview
  def post_email
    post_email = PostEmail.take

    PostMailer
      .with(post: post_email.post, subscriber: post_email.subscription.subscriber)
      .post_email
  end
end
