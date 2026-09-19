require "test_helper"

class Admin::Subscribers::StatusesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @author = authors(:instance)
  end

  test "redirects unauthenticated subscribe and unsubscribe" do
    pending_subscriber = subscribers(:reader_pending)
    active_subscriber = subscribers(:reader_one)

    patch subscribe_admin_subscriber_path(pending_subscriber)
    assert_redirected_to new_session_path

    patch unsubscribe_admin_subscriber_path(active_subscriber)
    assert_redirected_to new_session_path
  end

  test "subscribe creates a new pending subscription for an unsubscribed subscriber" do
    sign_in_as(@author)
    subscriber = subscribers(:reader_unsubscribed)

    assert_difference -> { subscriber.reload.subscriptions.count }, 1 do
      assert_enqueued_emails 2 do
        patch subscribe_admin_subscriber_path(subscriber)
      end
    end

    assert_redirected_to admin_subscriber_path(subscriber)
    assert_equal "Subscriber was successfully updated. Confirmation is pending.", flash[:success]
  end

  test "subscribe refreshes confirmation for a pending subscriber" do
    sign_in_as(@author)
    subscriber = subscribers(:reader_pending)
    original_subscription_id = subscriber.latest_subscription.id

    assert_no_difference -> { subscriber.reload.subscriptions.count } do
      assert_enqueued_emails 1 do
        patch subscribe_admin_subscriber_path(subscriber)
      end
    end

    assert_equal original_subscription_id, subscriber.reload.latest_subscription.id
    assert_redirected_to admin_subscriber_path(subscriber)
    assert_equal "Subscriber was successfully updated. Confirmation is pending.", flash[:success]
  end

  test "subscribe is idempotent for an active subscriber" do
    sign_in_as(@author)
    subscriber = subscribers(:reader_one)

    assert_no_changes -> { subscriber.reload.subscriptions.count } do
      assert_no_enqueued_emails do
        patch subscribe_admin_subscriber_path(subscriber)
      end
    end

    assert_redirected_to admin_subscriber_path(subscriber)
    assert_equal "Subscriber was successfully updated. Confirmation is pending.", flash[:success]
  end

  test "unsubscribe moves an active subscriber to unsubscribed" do
    sign_in_as(@author)
    subscriber = subscribers(:reader_one)

    assert_changes -> { subscriber.reload.unsubscribed? }, from: false, to: true do
      patch unsubscribe_admin_subscriber_path(subscriber)
    end

    assert_redirected_to admin_subscriber_path(subscriber)
    assert_equal "Subscriber was successfully unsubscribed.", flash[:success]
  end

  test "unsubscribe moves a pending subscriber to unsubscribed" do
    sign_in_as(@author)
    subscriber = subscribers(:reader_pending)

    assert_changes -> { subscriber.reload.unsubscribed? }, from: false, to: true do
      patch unsubscribe_admin_subscriber_path(subscriber)
    end

    assert_redirected_to admin_subscriber_path(subscriber)
    assert_equal "Subscriber was successfully unsubscribed.", flash[:success]
  end

  test "unsubscribe is idempotent for an unsubscribed subscriber" do
    sign_in_as(@author)
    subscriber = subscribers(:reader_unsubscribed)

    assert_no_changes -> { subscriber.reload.latest_subscription } do
      assert_no_enqueued_emails do
        patch unsubscribe_admin_subscriber_path(subscriber)
      end
    end

    assert_redirected_to admin_subscriber_path(subscriber)
    assert_equal "Subscriber was successfully unsubscribed.", flash[:success]
  end

  test "redirects to show when subscribe fails" do
    sign_in_as(@author)
    subscriber = subscribers(:reader_unsubscribed)

    temporarily_redefine_method(Subscriber, :subscribe, -> { false }) do
      patch subscribe_admin_subscriber_path(subscriber)
    end

    assert_redirected_to admin_subscriber_path(subscriber)
    assert_equal "Sorry, something went wrong.", flash[:alert]
  end
end
