require "test_helper"

class Subscriptions::ConfirmationsControllerTest < ActionDispatch::IntegrationTest
  test "show renders confirmation page without subscribing" do
    subscription = Subscription.create!(subscriber: subscribers(:reader_without_subscription), status: "pending_confirmation")

    assert_no_changes -> { subscription.reload.active? } do
      get subscription_confirmation_url(subscription.confirmation_token)
      assert_response :success
    end

    assert_select "h1", "Confirm your email subscription?"
    assert_select "form[action^='/subscriptions/'][action$='/confirm']" do
      assert_select "input[type=?][name=?][value=?]", "hidden", "_method", "patch"
    end
  end

  test "update confirms a pending subscription" do
    subscription = Subscription.create!(subscriber: subscribers(:reader_without_subscription), status: "pending_confirmation")

    assert_changes -> { subscription.reload.status }, from: "pending_confirmation", to: "active" do
      assert_changes -> { subscription.reload.confirmed_at.present? }, from: false, to: true do
        assert_enqueued_emails 1 do
          patch subscription_confirmation_path(subscription.confirmation_token)
        end
      end
    end

    assert_redirected_to root_url
    assert_equal "#{subscription.subscriber.email_address} is now subscribed!", flash[:success]
  end

  test "update redirects when a confirmation token is reused" do
    subscription = Subscription.create!(subscriber: subscribers(:reader_without_subscription), status: "pending_confirmation")
    token = subscription.confirmation_token

    patch subscription_confirmation_path(token)
    assert_redirected_to root_url

    patch subscription_confirmation_path(token)
    assert_redirected_to root_url
    assert_equal "Confirmation link is no longer valid.", flash[:alert]
  end

  test "show redirects for invalid token" do
    get subscription_confirmation_url("invalid")
    assert_redirected_to root_url

    assert_equal "Confirmation link is no longer valid.", flash[:alert]
  end

  test "update redirects for invalid token" do
    patch subscription_confirmation_path("invalid")
    assert_redirected_to root_url

    assert_equal "Confirmation link is no longer valid.", flash[:alert]
  end
end
