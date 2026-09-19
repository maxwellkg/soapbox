require "test_helper"

class SubscriberTest < ActiveSupport::TestCase
  test "validates presence of email address" do
    subscriber = Subscriber.new
    assert_not subscriber.valid?

    assert subscriber.errors.of_kind?(:email_address, :blank)

    subscriber.email_address = "foo@bar.com"
    assert subscriber.valid?
    assert_not subscriber.errors.of_kind?(:email_address, :blank)
  end

  test "validates uniqueness of email address" do
    subscriber = Subscriber.new(email_address: subscribers(:reader_one).email_address)
    assert_not subscriber.valid?

    assert subscriber.errors.of_kind?(:email_address, :taken)

    subscriber.email_address = "foo@bar.com"
    assert subscriber.valid?
    assert_not subscriber.errors.of_kind?(:email_address, :taken)
  end

  test "validates format of email address" do
    subscriber = Subscriber.new(email_address: "foobar@")
    assert_not subscriber.valid?

    assert subscriber.errors.of_kind?(:email_address, :invalid)

    subscriber.email_address = "foobar@example.com"
    assert subscriber.valid?
    assert_not subscriber.errors.of_kind?(:email_address, :invalid)
  end

  test "normalizes email address" do
    subscriber = subscribers(:reader_three)
    subscriber.update!(email_address: " fOO@bAr.com ")

    assert_equal "foo@bar.com", subscriber.email_address
  end

  test "searches by email address" do
    assert_equal [ subscribers(:reader_one).id ], Subscriber.search_email_address("reader.one").pluck(:id)
    assert_equal Subscriber.all.pluck(:id).sort, Subscriber.search_email_address(nil).pluck(:id).sort
    assert_equal [], Subscriber.search_email_address("no-such-subscriber").to_a
  end

  test "derives its status from its subscription" do
    pending_subscriber = subscribers(:reader_pending)
    active_subscriber = subscribers(:reader_one)
    unsubscribed_subscriber = subscribers(:reader_four)

    assert_equal "pending_confirmation", pending_subscriber.status
    assert pending_subscriber.pending_confirmation?
    assert_not pending_subscriber.active?
    assert_not pending_subscriber.unsubscribed?

    assert_equal "active", active_subscriber.status
    assert active_subscriber.active?
    assert_not active_subscriber.pending_confirmation?
    assert_not active_subscriber.unsubscribed?

    assert_equal "unsubscribed", unsubscribed_subscriber.status
    assert unsubscribed_subscriber.unsubscribed?
    assert_not unsubscribed_subscriber.active?
    assert_not unsubscribed_subscriber.pending_confirmation?
  end

  test "builds a pending confirmation subscription by default for new records" do
    subscriber = Subscriber.new(email_address: "new@example.com")

    assert subscriber.pending_confirmation?
  end

  test "latest subscription returns the newest persisted subscription" do
    subscriber = subscribers(:reader_four)

    assert_equal subscriptions(:reader_four_current_unsubscribed), subscriber.latest_subscription
  end

  test "scopes to active subscribers by latest subscription" do
    active = %i[ reader_one reader_two pagination_active_reader_01 pagination_active_reader_02 pagination_active_reader_03 pagination_active_reader_04 pagination_active_reader_05 pagination_active_reader_06 pagination_active_reader_07 pagination_active_reader_08 pagination_active_reader_09 pagination_active_reader_10 ].map { |key| subscribers(key) }

    assert_equal active.map(&:id).sort, Subscriber.active.pluck(:id).sort
  end

  test "scopes to pending confirmation subscribers by latest subscription" do
    subscription = Subscription.create!(subscriber: subscribers(:reader_without_subscription), status: "pending_confirmation")

    pending = [ subscribers(:reader_pending), subscription.subscriber ] + %i[ pagination_pending_reader_01 pagination_pending_reader_02 pagination_pending_reader_03 pagination_pending_reader_04 pagination_pending_reader_05 ].map { |key| subscribers(key) }

    assert_equal pending.map(&:id).sort, Subscriber.pending_confirmation.pluck(:id).sort
  end

  test "scopes to unsubscribed subscribers by latest subscription" do
    unsubscribed = %i[ reader_three reader_four reader_unsubscribed pagination_unsubscribed_reader_01 pagination_unsubscribed_reader_02 pagination_unsubscribed_reader_03 pagination_unsubscribed_reader_04 pagination_unsubscribed_reader_05 pagination_unsubscribed_reader_06 ].map { |key| subscribers(key) }

    assert_equal unsubscribed.map(&:id).sort, Subscriber.unsubscribed.pluck(:id).sort
  end

  test "for_status returns the matching scope" do
    assert_equal Subscriber.active.to_a, Subscriber.for_status(:active).to_a
    assert_equal Subscriber.pending_confirmation.to_a, Subscriber.for_status("pending_confirmation").to_a
    assert_equal Subscriber.unsubscribed.to_a, Subscriber.for_status("unsubscribed").to_a
    assert_equal [], Subscriber.for_status("unknown").to_a
    assert_equal Subscriber.all.to_a, Subscriber.for_status(nil).to_a
  end

  test "subscribe sends a confirmation email again for a pending subscriber" do
    subscriber = subscribers(:reader_pending)

    assert_no_changes -> { subscriber.reload.subscriptions.count } do
      assert_enqueued_emails 1 do
        assert subscriber.subscribe
      end
    end
  end

  test "subscribe is idempotent for an active subscriber" do
    subscriber = subscribers(:reader_one)

    assert_no_changes -> { subscriber.reload.subscriptions.count } do
      assert_no_enqueued_emails do
        assert subscriber.subscribe
      end
    end
  end

  test "subscribe creates a new pending subscription for an unsubscribed subscriber" do
    subscriber = subscribers(:reader_unsubscribed)

    assert_changes -> { subscriber.reload.pending_confirmation? }, from: false, to: true do
      assert_difference -> { subscriber.reload.subscriptions.count }, 1 do
        assert_enqueued_emails 2 do
          assert subscriber.subscribe
        end
      end
    end
  end

  test "unsubscribe moves a pending subscriber to unsubscribed" do
    subscriber = subscribers(:reader_pending)

    assert_changes -> { subscriber.reload.unsubscribed? }, from: false, to: true do
      assert subscriber.unsubscribe
    end
  end

  test "unsubscribe moves an active subscriber to unsubscribed" do
    subscriber = subscribers(:reader_one)

    assert_changes -> { subscriber.reload.unsubscribed? }, from: false, to: true do
      assert subscriber.unsubscribe
    end
  end

  test "unsubscribe is idempotent for an unsubscribed subscriber" do
    subscriber = subscribers(:reader_four)

    assert_no_changes -> { subscriber.reload.latest_subscription } do
      assert_no_enqueued_emails do
        assert subscriber.unsubscribe
      end
    end
  end

  test "find_by_unsubscribe_token returns the subscriber for a valid token and nil for an invalid token" do
    subscriber = subscribers(:reader_one)
    token = subscriber.unsubscribe_token

    assert_equal subscriber, Subscriber.find_by_unsubscribe_token(token)
    assert_nil Subscriber.find_by_unsubscribe_token("invalid-token")
  end

  test "find_by_unsubscribe_token! returns the subscriber for a valid token and raises for an invalid token" do
    subscriber = subscribers(:reader_one)
    token = subscriber.unsubscribe_token

    assert_equal subscriber, Subscriber.find_by_unsubscribe_token!(token)

    assert_raises(ActiveRecord::RecordNotFound) do
      Subscriber.find_by_unsubscribe_token!("invalid-token")
    end
  end
end
