class PostMailer < ApplicationMailer
  helper ApplicationHelper, PostsHelper

  def post_email
    @post = params[:post]
    @blog = Blog.instance!
    @subscriber = params[:subscriber]

    mail(
      to: @subscriber.email_address,
      subject: @post.title,
      message_stream: "broadcast",
      **unsubscribe_headers(@subscriber)
    )
  end
end
