require "test_helper"

class PostEmailTest < ActiveSupport::TestCase
  test "is invalid without a post" do
    post_email = PostEmail.new
    post_email.valid?
    assert post_email.errors.of_kind?(:post, :blank)

    post_email.post = posts(:published)
    post_email.valid?
    assert_not post_email.errors.of_kind?(:post, :blank)
  end

  test "is invalid without a subscription" do
    post_email = PostEmail.new
    post_email.valid?
    assert post_email.errors.of_kind?(:subscription, :blank)

    post_email.subscription = subscriptions(:reader_one_current)
    post_email.valid?
    assert_not post_email.errors.of_kind?(:subscription, :blank)
  end

  test "is unique to a post/subscription pair" do
    existing = post_emails(:reader_one_emailed_post)

    post_email = PostEmail.new(
      post: existing.post,
      subscription: existing.subscription
    )

    assert_not post_email.valid?
    assert post_email.errors.of_kind?(:post, :taken)

    post_email.subscription = subscriptions(:pagination_active_reader_01)

    assert post_email.valid?
    assert_not post_email.errors.of_kind?(:post, :taken)
  end

  test "is valid with all valid attributes" do
    post_email = PostEmail.new(
      post: posts(:published),
      subscription: subscriptions(:reader_two_current)
    )

    assert post_email.valid?
  end

  test "enqueues the email delivery" do
    post_email = post_emails(:reader_two_emailed_post)
    post_email.send(:enqueue_email)

    assert_enqueued_email_with PostMailer, :post_email, params: { post: post_email.post, subscriber: post_email.subscription.subscriber }
    deliver_enqueued_emails
    assert_emails 1
  end

  test "it automatically enqueues the emails after create" do
    post_email = PostEmail.create!(
      post: posts(:published),
      subscription: subscriptions(:pagination_active_reader_01)
    )

    assert_enqueued_email_with PostMailer, :post_email, params: { post: post_email.post, subscriber: post_email.subscription.subscriber }
  end

  test "is invalid unless the subscription is active" do
    pending = PostEmail.new(
      post: posts(:published),
      subscription: subscriptions(:reader_pending_confirmation)
    )
    assert_not pending.valid?
    assert pending.errors.of_kind?(:subscription, "must be active")

    unsubscribed = PostEmail.new(
      post: posts(:published),
      subscription: subscriptions(:reader_unsubscribed_current)
    )
    assert_not unsubscribed.valid?
    assert unsubscribed.errors.of_kind?(:subscription, "must be active")

    active = PostEmail.new(
      post: posts(:published),
      subscription: subscriptions(:pagination_active_reader_01)
    )
    assert active.valid?
    assert_not active.errors.of_kind?(:subscription, "must be active")
  end
end
