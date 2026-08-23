require "test_helper"

class Subscribers::SignupsControllerTest < ActionDispatch::IntegrationTest
  test "create signs up a new subscriber" do
    email_address = "new.subscriber@example.com"

    assert_difference -> { Subscriber.count }, 1 do
      submit_signup(email_address)
      assert_successful_signup_response
    end

    created = Subscriber.find_by!(email_address: email_address)

    assert_signup_emails_enqueued_for(created.latest_subscription)
  end

  test "create is idempotent for an active subscriber" do
    subscriber = subscribers(:reader_one)

    assert_no_difference [ -> { Subscriber.count }, -> { Subscription.count } ] do
      assert_no_enqueued_emails do
        post signups_url(format: :turbo_stream), params: {
          subscriber: {
            email_address: subscriber.email_address
          }
        }
      end

      assert_response :success
      assert_flash_message "Thanks for subscribing.", key: :success
    end
  end

  test "create creates a new pending subscription for an unsubscribed subscriber" do
    subscriber = subscribers(:reader_unsubscribed)

    assert_difference -> { subscriber.reload.subscriptions.count }, 1 do
      assert_enqueued_emails 2 do
        submit_signup(subscriber.email_address)
        assert_successful_signup_response
      end
    end

    assert_signup_emails_enqueued_for(subscriber.reload.latest_subscription)
  end

  test "create refreshes confirmation for a pending subscriber" do
    subscriber = subscribers(:reader_pending)
    original_subscription_id = subscriber.latest_subscription.id

    assert_no_difference -> { subscriber.reload.subscriptions.count } do
      submit_signup(subscriber.email_address)
      assert_successful_signup_response
    end

    assert_equal original_subscription_id, subscriber.reload.latest_subscription.id
    assert_enqueued_email_with SubscriptionsMailer, :confirmation, params: { subscription: subscriber.latest_subscription }
  end

  test "create re-renders form for invalid email address" do
    assert_no_difference [ -> { Subscriber.count }, -> { Subscription.count } ] do
      assert_no_enqueued_emails do
        submit_signup("not-an-email")
      end

      assert_response :unprocessable_entity
      assert_flash_message "Sorry, something went wrong", key: :alert
      assert_signup_form_present
      assert_select ".signup-errors", /prevented signup/
    end
  end

  test "create rate limits repeated signup attempts" do
    3.times do |index|
      post signups_url(format: :turbo_stream), params: {
        subscriber: {
          email_address: "reader#{index}@example.com"
        }
      }

      assert_response :success
    end

    assert_no_difference [ -> { Subscriber.count }, -> { Subscription.count } ] do
      assert_no_enqueued_emails do
        submit_signup("reader-over-limit@example.com")
      end

      assert_response :too_many_requests
      assert_flash_message "Too many signup attempts. Try again in 10 minutes.", key: :alert
      assert_signup_form_present
    end
  end

  test "create ignores submissions that fill the honeypot field" do
    assert_no_difference [ -> { Subscriber.count }, -> { Subscription.count } ] do
      assert_no_enqueued_emails do
        submit_signup("reader@example.com", name: "Spam Bot")
      end

      assert_response :success
      assert_flash_message "Thanks for subscribing.", key: :success
      assert_signup_form_present
    end
  end

  private
    def submit_signup(email_address, name: nil)
      post signups_url(format: :turbo_stream), params: {
        subscriber: {
          name:,
          email_address:
        }.compact
      }
    end

    def assert_successful_signup_response
      assert_response :success
      assert_flash_message "Check your inbox to confirm your subscription.", key: :success
    end

    def assert_signup_form_present
      assert_select "input[name='subscriber[email_address]']"
      assert_select "button", text: "subscribe"
    end

    def assert_signup_emails_enqueued_for(subscription)
      assert_enqueued_email_with SubscriptionsMailer, :confirmation, params: { subscription: subscription }
      assert_enqueued_email_with SubscriptionsMailer, :new_subscriber_author_notification, params: { subscription: subscription }
    end
end
