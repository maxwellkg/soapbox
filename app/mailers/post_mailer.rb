class PostMailer < ApplicationMailer
  helper PostsHelper

  def post_email
    @post = params[:post]
    @subscriber = params[:subscriber]

    mail(
      to: @subscriber.email_address,
      subject: @post.title,
      list_unsubscribe: subscriber_unsubscribe_url(@subscriber),
      message_stream: "broadcast"
    )
  end
end
