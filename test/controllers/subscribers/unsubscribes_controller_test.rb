require "test_helper"

class Subscribers::UnsubscribesControllerTest < ActionDispatch::IntegrationTest
  test "unsubscribes an active subscriber" do
    subscriber = subscribers(:reader_three)
    subscription = subscriber.active_subscription

    assert_changes -> { subscription.reload.active? }, from: true, to: false do
      get subscriber_unsubscribe_url(subscriber)
      assert_redirected_to root_url
    end

    assert_equal "#{subscriber.email_address} has been unsubscribed", flash[:success]
  end

  test "succeeds for inactive subscriber" do
    subscriber = subscribers(:reader_without_subscription)

    get subscriber_unsubscribe_url(subscriber)
    assert_redirected_to root_url

    assert_equal "#{subscriber.email_address} has been unsubscribed", flash[:success]
  end

  test "gives alert if unsubscribe fails" do
    subscriber = subscribers(:reader_three)

    temporarily_redefine_method(Subscriber, :unsubscribe, -> { false }) do
      get subscriber_unsubscribe_url(subscriber)
      assert_redirected_to root_url
    end

    assert_equal "Sorry, something went wrong. Please try again.", flash[:alert]
  end

  test "redirects for expired/invalid token" do
    get unsubscribe_url("invalid")
    assert_redirected_to root_url

    assert_equal "Unsubscribe link is invalid or has expired.", flash[:alert]
  end
end
