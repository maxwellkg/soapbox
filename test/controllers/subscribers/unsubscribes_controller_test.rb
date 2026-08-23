require "test_helper"

class Subscribers::UnsubscribesControllerTest < ActionDispatch::IntegrationTest
  test "show renders unsubscribe confirmation without unsubscribing" do
    subscriber = subscribers(:reader_one)
    subscription = subscriber.latest_subscription

    assert_no_changes -> { subscription.reload.active? } do
      get subscriber_unsubscribe_url(subscriber)
      assert_response :success
    end

    assert_select "h1", "Unsubscribe from email updates?"
    assert_select "form[action=?]", unsubscribe_path(subscriber.unsubscribe_token) do
      assert_select "input[type=?][name=?][value=?]", "hidden", "_method", "patch"
    end
  end

  test "complete unsubscribes an active subscriber" do
    subscriber = subscribers(:reader_one)
    subscription = subscriber.latest_subscription

    assert_changes -> { subscription.reload.status }, from: "active", to: "unsubscribed" do
      assert_no_enqueued_emails do
        patch unsubscribe_path(subscriber.unsubscribe_token)
      end
      assert_redirected_to root_url
    end

    assert_equal "#{subscriber.email_address} has been unsubscribed", flash[:success]
  end

  test "complete succeeds for unsubscribed subscriber" do
    subscriber = subscribers(:reader_unsubscribed)

    assert_no_enqueued_emails do
      patch unsubscribe_path(subscriber.unsubscribe_token)
    end
    assert_redirected_to root_url

    assert_equal "#{subscriber.email_address} has been unsubscribed", flash[:success]
  end

  test "complete gives alert if unsubscribe fails" do
    subscriber = subscribers(:reader_three)

    temporarily_redefine_method(Subscriber, :unsubscribe, -> { false }) do
      assert_no_enqueued_emails do
        patch unsubscribe_path(subscriber.unsubscribe_token)
      end
      assert_redirected_to root_url
    end

    assert_equal "Sorry, something went wrong. Please try again.", flash[:alert]
  end

  test "show redirects for expired/invalid token" do
    get unsubscribe_url("invalid")
    assert_redirected_to root_url

    assert_equal "Unsubscribe link is invalid or has expired.", flash[:alert]
  end

  test "complete redirects for expired/invalid token" do
    patch unsubscribe_path("invalid")
    assert_redirected_to root_url

    assert_equal "Unsubscribe link is invalid or has expired.", flash[:alert]
  end
end
