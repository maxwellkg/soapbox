# Preview all emails at http://localhost:3000/rails/mailers/subscriptions_mailer
class SubscriptionsMailerPreview < ActionMailer::Preview
  def new_subscriber_author_notification
    subscription = Subscription.pending_confirmation.first || Subscription.create!(
      subscriber: Subscriber.first || Subscriber.create!(email_address: "preview@example.com"),
      status: "pending_confirmation"
    )

    SubscriptionsMailer.with(subscription: subscription).new_subscriber_author_notification
  end

  def confirmation
    subscription = Subscription.pending_confirmation.first || Subscription.create!(
      subscriber: Subscriber.first || Subscriber.create!(email_address: "preview@example.com"),
      status: "pending_confirmation"
    )

    SubscriptionsMailer.with(subscription: subscription).confirmation
  end

  def subscribed
    SubscriptionsMailer.with(subscription: Subscription.active.first || begin
      subscription = Subscription.create!(
        subscriber: Subscriber.first || Subscriber.create!(email_address: "preview@example.com"),
        status: "pending_confirmation"
      )
      subscription.confirm
      subscription
    end).subscribed
  end
end
