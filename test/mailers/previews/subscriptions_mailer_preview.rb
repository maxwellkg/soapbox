# Preview all emails at http://localhost:3000/rails/mailers/subscriptions_mailer
class SubscriptionsMailerPreview < ActionMailer::Preview
  def activated
    SubscriptionsMailer.activated(Subscription.take)
  end

  def deactivated
    SubscriptionsMailer.deactivated(Subscription.take)
  end
end
