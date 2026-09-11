module Subscription::Notifications
  extend ActiveSupport::Concern

  included do
    after_create_commit :send_new_subscriber_author_notification

    # New subscriptions always start as pending_confirmation (enforced by validation),
    # so the confirmation email is always sent on create.
    after_create_commit :send_confirmation_email
    after_commit :send_subscribed_email, if: -> { saved_change_to_status?(to: "active") }
  end

  private
    def send_new_subscriber_author_notification
      new_subscriber_author_notification_email.deliver_later
    end

    def new_subscriber_author_notification_email
      SubscriptionsMailer.with(subscription: self).new_subscriber_author_notification
    end

    def send_confirmation_email
      confirmation_email.deliver_later
    end

    def confirmation_email
      SubscriptionsMailer.with(subscription: self).confirmation
    end

    def send_subscribed_email
      subscribed_email.deliver_later
    end

    def subscribed_email
      SubscriptionsMailer.with(subscription: self).subscribed
    end
end
