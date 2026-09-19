require "test_helper"

class SubscriptionsMailerTest < ActionMailer::TestCase
  private def create_subscriber_without_subscription(email_address)
    Subscriber.create!(email_address:).tap do |subscriber|
      subscriber.subscriptions.destroy_all
    end
  end

  test "new subscriber author notification sends to the author with signup subject" do
    subscription = Subscription.create!(subscriber: subscribers(:reader_without_subscription), status: "pending_confirmation")
    email = SubscriptionsMailer.with(subscription: subscription).new_subscriber_author_notification

    assert_equal [ Author.instance!.email_address ], email.to
    assert_equal "New subscription signup for #{Blog.instance!.title}", email.subject
  end

  test "new subscriber author notification includes the subscriber email and admin link" do
    subscription = Subscription.create!(subscriber: subscribers(:reader_without_subscription), status: "pending_confirmation")
    email = SubscriptionsMailer.with(subscription: subscription).new_subscriber_author_notification

    assert_includes email.html_part.body.decoded, subscription.subscriber.email_address
    assert_includes email.text_part.body.decoded, subscription.subscriber.email_address
    assert_includes email.html_part.body.decoded, admin_subscriber_path(subscription.subscriber)
    assert_includes email.text_part.body.decoded, admin_subscriber_path(subscription.subscriber)
  end

  test "confirmation email sends to the subscriber with confirm subject" do
    subscription = Subscription.create!(subscriber: subscribers(:reader_without_subscription), status: "pending_confirmation")
    email = SubscriptionsMailer.with(subscription: subscription).confirmation

    assert_equal [ subscription.subscriber.email_address ], email.to
    assert_equal "Confirm your subscription to #{Blog.instance!.title}", email.subject
  end

  test "confirmation email includes confirmation link" do
    subscription = Subscription.create!(subscriber: subscribers(:reader_without_subscription), status: "pending_confirmation")
    email = SubscriptionsMailer.with(subscription: subscription).confirmation

    assert_match %r{/subscriptions/.+/confirm}, email.html_part.body.decoded
    assert_match %r{/subscriptions/.+/confirm}, email.text_part.body.decoded
  end

  test "subscribed email sends to the subscriber with the blog title subject" do
    subscription = subscriptions(:reader_one_current)
    email = SubscriptionsMailer.with(subscription: subscription).subscribed

    assert_equal [ subscription.subscriber.email_address ], email.to
    assert_equal "You're subscribed to #{Blog.instance!.title}", email.subject
  end

  test "subscribed email includes unsubscribe link" do
    subscription = subscriptions(:reader_one_current)
    email = SubscriptionsMailer.with(subscription: subscription).subscribed

    unsubscribe_path = "/subscribers/#{subscription.subscriber.unsubscribe_token}/unsubscribe"
    assert_includes email.html_part.body.decoded, unsubscribe_path
    assert_includes email.text_part.body.decoded, unsubscribe_path
  end

  test "subscribed email sets list_unsubscribe header" do
    subscription = subscriptions(:reader_one_current)
    email = SubscriptionsMailer.with(subscription: subscription).subscribed

    assert_not_nil email.header["List-Unsubscribe"]
    assert_includes email.header["List-Unsubscribe"].value, subscription.subscriber.unsubscribe_token
  end

  test "author notification, confirmation, and subscribed emails render html and text parts with the blog title" do
    author_notification_subscription = Subscription.create!(subscriber: create_subscriber_without_subscription("author-notification@example.com"), status: "pending_confirmation")
    confirmation_subscription = Subscription.create!(subscriber: create_subscriber_without_subscription("confirmation@example.com"), status: "pending_confirmation")
    subscribed_subscription = subscriptions(:reader_one_current)

    author_notification = SubscriptionsMailer.with(subscription: author_notification_subscription).new_subscriber_author_notification
    assert_equal "multipart/alternative", author_notification.mime_type
    assert_equal 2, author_notification.parts.size
    assert_includes author_notification.html_part.body.decoded, Blog.instance!.title
    assert_includes author_notification.text_part.body.decoded, Blog.instance!.title

    confirmation = SubscriptionsMailer.with(subscription: confirmation_subscription).confirmation
    assert_equal "multipart/alternative", confirmation.mime_type
    assert_equal 2, confirmation.parts.size
    assert_includes confirmation.html_part.body.decoded, Blog.instance!.title
    assert_includes confirmation.text_part.body.decoded, Blog.instance!.title

    subscribed = SubscriptionsMailer.with(subscription: subscribed_subscription).subscribed
    assert_equal "multipart/alternative", subscribed.mime_type
    assert_equal 2, subscribed.parts.size
    assert_includes subscribed.html_part.body.decoded, Blog.instance!.title
    assert_includes subscribed.text_part.body.decoded, Blog.instance!.title
  end

  test "html emails apply premailer transformations" do
    author_notification_subscription = Subscription.create!(subscriber: create_subscriber_without_subscription("premailer-author-notification@example.com"), status: "pending_confirmation")
    confirmation_subscription = Subscription.create!(subscriber: create_subscriber_without_subscription("premailer-confirmation@example.com"), status: "pending_confirmation")
    subscribed_subscription = subscriptions(:reader_one_current)

    author_notification = SubscriptionsMailer.with(subscription: author_notification_subscription).new_subscriber_author_notification
    author_notification.deliver_now
    confirmation = SubscriptionsMailer.with(subscription: confirmation_subscription).confirmation
    confirmation.deliver_now
    subscribed = SubscriptionsMailer.with(subscription: subscribed_subscription).subscribed
    subscribed.deliver_now

    author_notification_html = ActionMailer::Base.deliveries[-3].html_part.body.decoded
    confirmation_html = ActionMailer::Base.deliveries[-2].html_part.body.decoded
    subscribed_html = ActionMailer::Base.deliveries[-1].html_part.body.decoded

    assert_match(/class="blog-title"[^>]*style="[^"]+"/i, author_notification_html)
    assert_no_match(/<link[^>]+stylesheet/i, author_notification_html)
    assert_match(/class="blog-title"[^>]*style="[^"]+"/i, confirmation_html)
    assert_no_match(/<link[^>]+stylesheet/i, confirmation_html)
    assert_match(/class="blog-title"[^>]*style="[^"]+"/i, subscribed_html)
    assert_no_match(/<link[^>]+stylesheet/i, subscribed_html)
  end
end
