require "test_helper"

class Admin::Subscribers::StatusesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @author = authors(:one)
  end

  test "redirects unauthenticated activate and deactivate" do
    inactive = subscribers(:reader_without_subscription)
    active = subscribers(:reader_three)

    patch activate_admin_subscriber_path(inactive)
    assert_redirected_to new_session_path

    patch deactivate_admin_subscriber_path(active)
    assert_redirected_to new_session_path
  end

  test "activates an inactive subscriber" do
    sign_in_as(@author)
    subscriber = subscribers(:reader_without_subscription)

    assert_changes -> { subscriber.reload.active? }, from: false, to: true do
      assert_enqueued_emails 1 do
        patch activate_admin_subscriber_path(subscriber)
      end
    end

    assert_redirected_to admin_subscriber_path(subscriber)
    assert_equal "Subscriber was successfully activated.", flash[:success]
  end

  test "deactivates an active subscriber" do
    sign_in_as(@author)
    subscriber = subscribers(:reader_three)

    assert_changes -> { subscriber.reload.active? }, from: true, to: false do
      assert_enqueued_emails 1 do
        patch deactivate_admin_subscriber_path(subscriber)
      end
    end

    assert_redirected_to admin_subscriber_path(subscriber)
    assert_equal "Subscriber was successfully deactivated.", flash[:success]
  end

  test "activate is idempotent for active subscriber" do
    sign_in_as(@author)
    subscriber = subscribers(:reader_three)

    assert_no_changes -> { subscriber.reload.active? } do
      assert_no_enqueued_emails do
        patch activate_admin_subscriber_path(subscriber)
      end
    end

    assert_redirected_to admin_subscriber_path(subscriber)
    assert_equal "Subscriber was successfully activated.", flash[:success]
  end

  test "deactivate is idempotent for inactive subscriber" do
    sign_in_as(@author)
    subscriber = subscribers(:reader_without_subscription)

    assert_no_changes -> { subscriber.reload.active? } do
      assert_no_enqueued_emails do
        patch deactivate_admin_subscriber_path(subscriber)
      end
    end

    assert_redirected_to admin_subscriber_path(subscriber)
    assert_equal "Subscriber was successfully deactivated.", flash[:success]
  end

  test "renders edit when status update fails" do
    sign_in_as(@author)
    subscriber = subscribers(:reader_without_subscription)

    temporarily_redefine_method(Subscriber, :activate, -> { false }) do
      patch activate_admin_subscriber_path(subscriber)
    end

    assert_response :unprocessable_entity
    assert_select "h1", "Edit Subscriber"
    assert_equal "Sorry, something went wrong.", flash[:alert]
  end
end
