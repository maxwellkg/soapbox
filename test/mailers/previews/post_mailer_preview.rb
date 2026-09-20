# Preview all emails at http://localhost:3000/rails/mailers/post_mailer
class PostMailerPreview < ActionMailer::Preview
  def post_email
    PostMailer
      .with(post: Post.published.take, subscriber: Subscriber.active.take)
      .post_email
  end

  def post_email_with_code
    post = Post.find_by(slug: "understanding-ruby-metaprogramming-deep-dive")
    subscriber = Subscriber.active.take

    PostMailer
      .with(post:, subscriber:)
      .post_email
  end
end
