class PostMailer < ApplicationMailer
  helper ApplicationHelper, PostsHelper

  default(
    from: -> { email_address_with_name(updates_address, blog_title) },
    reply_to: -> { author_address }
  )

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

  private
    def updates_address
      blog_email_address("updates")
    end

    def author_address
      Author.instance!.email_address
    end
end
