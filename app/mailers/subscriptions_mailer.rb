class SubscriptionsMailer < ApplicationMailer
  helper ApplicationHelper, PostsHelper

  def activated(subscription)
    @blog = Blog.instance!
    @subscription = subscription
    @subscriber = subscription.subscriber

    mail(
      to: @subscriber.email_address,
      subject: "You're subscribed to #{@blog.title}",
      list_unsubscribe: subscriber_unsubscribe_url(@subscriber)
    )
  end

  def deactivated(subscription)
    @blog = Blog.instance!
    @subscription = subscription
    @subscriber = subscription.subscriber

    mail(
      to: @subscriber.email_address,
      subject: "You've been unsubscribed from #{@blog.title}"
    )
  end
end
