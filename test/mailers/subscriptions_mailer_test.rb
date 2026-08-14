require "test_helper"

class SubscriptionsMailerTest < ActionMailer::TestCase
  test "activated email sends to the subscriber with the blog title subject" do
    subscription = subscriptions(:reader_one_active)
    email = SubscriptionsMailer.activated(subscription)

    assert_equal [ subscription.subscriber.email_address ], email.to
    assert_equal "You're subscribed to #{Blog.instance!.title}", email.subject
  end

  test "activated email includes unsubscribe link" do
    subscription = subscriptions(:reader_one_active)
    email = SubscriptionsMailer.activated(subscription)

    unsubscribe_path = "/subscribers/#{subscription.subscriber.unsubscribe_token}/unsubscribe"
    assert_includes email.html_part.body.decoded, unsubscribe_path
    assert_includes email.text_part.body.decoded, unsubscribe_path
  end

  test "activated email sets list_unsubscribe header" do
    subscription = subscriptions(:reader_one_active)
    email = SubscriptionsMailer.activated(subscription)

    assert_not_nil email.header["List-Unsubscribe"]
    assert_includes email.header["List-Unsubscribe"].value, subscription.subscriber.unsubscribe_token
  end

  test "deactivated email sends to the subscriber with unsubscribed subject" do
    subscription = subscriptions(:reader_one_active)
    subscription.deactivate
    subscription.reload

    email = SubscriptionsMailer.deactivated(subscription)

    assert_equal [ subscription.subscriber.email_address ], email.to
    assert_equal "You've been unsubscribed from #{Blog.instance!.title}", email.subject
  end

  test "both emails render html and text parts with the blog title" do
    subscription = subscriptions(:reader_one_active)

    activated = SubscriptionsMailer.activated(subscription)
    assert_equal "multipart/alternative", activated.mime_type
    assert_equal 2, activated.parts.size
    assert_includes activated.html_part.body.decoded, Blog.instance!.title
    assert_includes activated.text_part.body.decoded, Blog.instance!.title

    deactivated = SubscriptionsMailer.deactivated(subscription)
    assert_equal "multipart/alternative", deactivated.mime_type
    assert_equal 2, deactivated.parts.size
    assert_includes deactivated.html_part.body.decoded, Blog.instance!.title
    assert_includes deactivated.text_part.body.decoded, Blog.instance!.title
  end

  test "deactivated email text confirms the unsubscribe" do
    subscription = subscriptions(:reader_one_active)
    email = SubscriptionsMailer.deactivated(subscription)

    assert_includes email.text_part.body.decoded, "has been unsubscribed from"
  end

  test "html emails apply premailer transformations" do
    subscription = subscriptions(:reader_one_active)

    activated = SubscriptionsMailer.activated(subscription)
    activated.deliver_now
    deactivated = SubscriptionsMailer.deactivated(subscription)
    deactivated.deliver_now

    activated_html = ActionMailer::Base.deliveries[-2].html_part.body.decoded
    deactivated_html = ActionMailer::Base.deliveries[-1].html_part.body.decoded

    assert_match(/class="blog-title"[^>]*style="[^"]+"/i, activated_html)
    assert_no_match(/<link[^>]+stylesheet/i, activated_html)
    assert_match(/class="blog-title"[^>]*style="[^"]+"/i, deactivated_html)
    assert_no_match(/<link[^>]+stylesheet/i, deactivated_html)
  end
end
