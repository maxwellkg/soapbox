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

    post_email.subscription = subscriptions(:reader_one_active)
    post_email.valid?
    assert_not post_email.errors.of_kind?(:subscription, :blank)
  end

  test "is unique to a post/subscription pair" do
    existing = post_emails(:reader_one_email)

    post_email = PostEmail.new(
      post: existing.post,
      subscription: existing.subscription
    )

    assert_not post_email.valid?
    assert post_email.errors.of_kind?(:post, :taken)

    post_email.subscription = subscriptions(:reader_four_active)

    assert post_email.valid?
    assert_not post_email.errors.of_kind?(:post, :taken)
  end

  test "is valid with all valid attributes" do
    post_email = PostEmail.new(
      post: posts(:published),
      subscription: subscriptions(:reader_two_active)
    )

    assert post_email.valid?
  end

  test "enqueues the email delivery" do
    post_email = post_emails(:reader_two_email)
    post_email.send(:enqueue_email)

    assert_enqueued_email_with PostMailer, :post_email, params: { post: post_email.post, subscriber: post_email.subscription.subscriber }
    deliver_enqueued_emails
    assert_emails 1
  end

  test "it automatically enqueues the emails after create" do
    post_email = PostEmail.create!(
      post: posts(:published),
      subscription: subscriptions(:reader_three_active)
    )

    assert_enqueued_email_with PostMailer, :post_email, params: { post: post_email.post, subscriber: post_email.subscription.subscriber }
  end
end
