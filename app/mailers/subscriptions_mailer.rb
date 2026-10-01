class SubscriptionsMailer < ApplicationMailer
  helper ApplicationHelper, PostsHelper

  def new_subscriber_author_notification
    @blog = Blog.instance!
    @subscription = params[:subscription]
    @subscriber = @subscription.subscriber

    mail(
      to: @blog.author.email_address,
      subject: "New subscription signup for #{@blog.title}"
    )
  end

  def confirmation
    @blog = Blog.instance!
    @subscription = params[:subscription]
    @subscriber = @subscription.subscriber

    mail(
      to: @subscriber.email_address,
      subject: "Confirm your subscription to #{@blog.title}"
    )
  end

  def subscribed
    @blog = Blog.instance!
    @subscription = params[:subscription]
    @subscriber = @subscription.subscriber

    mail(
      to: @subscriber.email_address,
      subject: "You're subscribed to #{@blog.title}",
      **unsubscribe_headers(@subscriber)
    )
  end
end
