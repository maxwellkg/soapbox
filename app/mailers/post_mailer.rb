class PostMailer < ApplicationMailer
  helper ApplicationHelper, PostsHelper

  def post_email
    @post = params[:post]
    @blog = Blog.instance!
    @subscriber = params[:subscriber]

    mail(
      to: @subscriber.email_address,
      subject: @post.title,
      list_unsubscribe: subscriber_unsubscribe_url(@subscriber),
      message_stream: "broadcast"
    )
  end
end
