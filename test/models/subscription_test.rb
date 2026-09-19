require "test_helper"

class SubscriptionTest < ActiveSupport::TestCase
  test "is invalid without a subscriber" do
    subscription = Subscription.new(status: "pending_confirmation")
    assert_not subscription.valid?

    assert subscription.errors.of_kind?(:subscriber, :blank)

    subscription.subscriber = subscribers(:reader_without_subscription)

    assert subscription.valid?
    assert_not subscription.errors.of_kind?(:subscriber, :blank)
  end

  test "only allows one current subscription per subscriber" do
    existing = subscriptions(:reader_two_current)

    new_subscription = existing.subscriber.subscriptions.build(status: "pending_confirmation")
    assert_not new_subscription.valid?

    assert new_subscription.errors.of_kind?(:subscriber_id, :taken)

    new_subscription.status = "unsubscribed"
    new_subscription.unsubscribed_at = Time.current

    assert_not new_subscription.valid?
    assert_not new_subscription.errors.of_kind?(:subscriber_id, :taken)
  end

  test "scope for current" do
    current_subscriptions = [
      subscriptions(:reader_pending_confirmation),
      subscriptions(:reader_one_current),
      subscriptions(:reader_two_current),
      subscriptions(:reader_three_previous_active),
      subscriptions(:reader_four_previous_active),
      subscriptions(:pagination_active_reader_01),
      subscriptions(:pagination_active_reader_02),
      subscriptions(:pagination_active_reader_03),
      subscriptions(:pagination_active_reader_04),
      subscriptions(:pagination_active_reader_05),
      subscriptions(:pagination_active_reader_06),
      subscriptions(:pagination_active_reader_07),
      subscriptions(:pagination_active_reader_08),
      subscriptions(:pagination_active_reader_09),
      subscriptions(:pagination_active_reader_10),
      subscriptions(:pagination_pending_reader_01),
      subscriptions(:pagination_pending_reader_02),
      subscriptions(:pagination_pending_reader_03),
      subscriptions(:pagination_pending_reader_04),
      subscriptions(:pagination_pending_reader_05)
    ]

    assert_equal current_subscriptions.map(&:id).sort, Subscription.current.map(&:id).sort
  end

  test "scope for active" do
    active_subscriptions = [
      subscriptions(:reader_one_current),
      subscriptions(:reader_two_current),
      subscriptions(:reader_three_previous_active),
      subscriptions(:reader_four_previous_active),
      subscriptions(:pagination_active_reader_01),
      subscriptions(:pagination_active_reader_02),
      subscriptions(:pagination_active_reader_03),
      subscriptions(:pagination_active_reader_04),
      subscriptions(:pagination_active_reader_05),
      subscriptions(:pagination_active_reader_06),
      subscriptions(:pagination_active_reader_07),
      subscriptions(:pagination_active_reader_08),
      subscriptions(:pagination_active_reader_09),
      subscriptions(:pagination_active_reader_10)
    ]

    assert_equal active_subscriptions.map(&:id).sort, Subscription.active.map(&:id).sort
  end

  test "scope for pending confirmation" do
    subscription = Subscription.create!(subscriber: subscribers(:reader_without_subscription), status: "pending_confirmation")

    assert_includes Subscription.pending_confirmation, subscription
  end

  test "scope for unsubscribed" do
    unsubscribed_subscriptions = [
      subscriptions(:reader_unsubscribed_current),
      subscriptions(:reader_three_current_unsubscribed),
      subscriptions(:reader_four_previous_unsubscribed),
      subscriptions(:reader_four_current_unsubscribed),
      subscriptions(:pagination_unsubscribed_reader_01),
      subscriptions(:pagination_unsubscribed_reader_02),
      subscriptions(:pagination_unsubscribed_reader_03),
      subscriptions(:pagination_unsubscribed_reader_04),
      subscriptions(:pagination_unsubscribed_reader_05),
      subscriptions(:pagination_unsubscribed_reader_06)
    ]

    assert_equal unsubscribed_subscriptions.map(&:id).sort, Subscription.unsubscribed.map(&:id).sort
  end

  test "supports confirmation token finder methods while pending confirmation" do
    subscription = Subscription.create!(subscriber: subscribers(:reader_without_subscription), status: "pending_confirmation")
    token = subscription.confirmation_token

    assert_equal subscription, Subscription.find_by_confirmation_token(token)
    assert_equal subscription, Subscription.find_by_confirmation_token!(token)
  end

  test "confirmation token becomes invalid after confirmation" do
    subscription = Subscription.create!(subscriber: subscribers(:reader_without_subscription), status: "pending_confirmation")
    token = subscription.confirmation_token

    assert subscription.confirm

    assert_nil Subscription.find_by_confirmation_token(token)
    assert_raises(ActiveRecord::RecordNotFound) do
      Subscription.find_by_confirmation_token!(token)
    end
  end

  test "confirmation token becomes invalid after unsubscribe" do
    subscription = Subscription.create!(subscriber: subscribers(:reader_without_subscription), status: "pending_confirmation")
    token = subscription.confirmation_token

    assert subscription.unsubscribe

    assert_nil Subscription.find_by_confirmation_token(token)
  end

  test "confirm activates a pending subscription and sets confirmed at" do
    subscription = Subscription.create!(subscriber: subscribers(:reader_without_subscription), status: "pending_confirmation")

    freeze_time do
      assert_changes -> { subscription.reload.status }, from: "pending_confirmation", to: "active" do
        assert_changes -> { subscription.reload.confirmed_at }, to: Time.current do
          assert_enqueued_emails 1 do
            assert subscription.confirm
          end
        end
      end
    end

    assert_nil subscription.reload.unsubscribed_at
  end

  test "confirm is idempotent for active subscriptions" do
    subscription = subscriptions(:reader_one_current)

    assert_no_changes -> { subscription.reload.attributes.slice("status", "confirmed_at", "unsubscribed_at") } do
      assert_no_enqueued_emails do
        assert subscription.confirm
      end
    end
  end

  test "confirm fails for unsubscribed subscriptions" do
    subscription = subscriptions(:reader_four_current_unsubscribed)

    assert_not subscription.confirm
    assert_equal "unsubscribed", subscription.reload.status
  end

  test "unsubscribe moves pending subscriptions to unsubscribed and sets unsubscribed at" do
    subscription = Subscription.create!(subscriber: subscribers(:reader_without_subscription), status: "pending_confirmation")

    freeze_time do
      assert_changes -> { subscription.reload.status }, from: "pending_confirmation", to: "unsubscribed" do
        assert_changes -> { subscription.reload.unsubscribed_at }, to: Time.current do
          assert subscription.unsubscribe
        end
      end
    end

    assert_nil subscription.reload.confirmed_at
  end

  test "unsubscribe moves active subscriptions to unsubscribed and preserves confirmed at" do
    subscription = subscriptions(:reader_one_current)
    confirmed_at = subscription.confirmed_at

    freeze_time do
      assert_changes -> { subscription.reload.status }, from: "active", to: "unsubscribed" do
        assert_changes -> { subscription.reload.unsubscribed_at }, to: Time.current do
          assert subscription.unsubscribe
        end
      end
    end

    assert_equal confirmed_at, subscription.reload.confirmed_at
  end

  test "unsubscribe is idempotent for unsubscribed subscriptions" do
    subscription = subscriptions(:reader_four_current_unsubscribed)

    assert_no_changes -> { subscription.reload.attributes.slice("status", "confirmed_at", "unsubscribed_at") } do
      assert_no_enqueued_emails do
        assert subscription.unsubscribe
      end
    end
  end

  test "send confirmation enqueues confirmation email for pending subscriptions" do
    subscription = Subscription.create!(subscriber: subscribers(:reader_without_subscription), status: "pending_confirmation")

    assert_enqueued_emails 1 do
      assert subscription.send_confirmation
    end
  end

  test "send confirmation is rejected for non-pending subscriptions" do
    subscription = subscriptions(:reader_one_current)

    assert_no_enqueued_emails do
      assert_not subscription.send_confirmation
    end
  end

  test "creating a pending subscription enqueues a confirmation email and author notification" do
    subscription = Subscription.new(subscriber: subscribers(:reader_without_subscription), status: "pending_confirmation")

    assert_enqueued_emails 2 do
      subscription.save!
    end
  end

  test "confirming a subscription enqueues a subscribed email" do
    subscription = Subscription.create!(subscriber: subscribers(:reader_without_subscription), status: "pending_confirmation")

    assert_enqueued_emails 1 do
      assert subscription.confirm
    end
  end

  test "unsubscribing a subscription enqueues no email" do
    subscription = subscriptions(:reader_one_current)

    assert_no_enqueued_emails do
      assert subscription.unsubscribe
    end
  end

  test "an unrelated update enqueues no email" do
    subscription = subscriptions(:reader_one_current)

    assert_no_enqueued_emails do
      subscription.touch
    end
  end

  test "new subscriptions must start pending confirmation" do
    subscription = Subscription.new(subscriber: subscribers(:reader_without_subscription), status: "active")
    assert_not subscription.valid?

    assert subscription.errors.of_kind?(:status, "must start as 'pending_confirmation'")
  end

  test "is invalid when pending subscription has lifecycle timestamps" do
    subscription = Subscription.new(
      subscriber: subscribers(:reader_without_subscription),
      status: "pending_confirmation",
      confirmed_at: Time.current,
      unsubscribed_at: Time.current
    )

    assert_not subscription.valid?
    assert subscription.errors.of_kind?(:confirmed_at, "must be blank while subscription is pending confirmation")
    assert subscription.errors.of_kind?(:unsubscribed_at, "must be blank while subscription is pending confirmation")
  end

  test "is invalid when active subscription has unsubscribed at" do
    subscription = Subscription.new(
      subscriber: subscribers(:reader_without_subscription),
      status: "active",
      confirmed_at: Time.current,
      unsubscribed_at: Time.current
    )

    assert_not subscription.valid?
    assert subscription.errors.of_kind?(:unsubscribed_at, "must be blank while subscription is active")
  end

  test "confirm overwrites any pre-filled confirmed at with the transition time" do
    subscription = Subscription.create!(subscriber: subscribers(:reader_without_subscription), status: "pending_confirmation")
    subscription.confirmed_at = 1.day.ago

    freeze_time do
      assert_changes -> { subscription.reload.confirmed_at }, to: Time.current do
        assert subscription.confirm
      end
    end
  end

  test "unsubscribe overwrites any pre-filled unsubscribed at with the transition time" do
    subscription = subscriptions(:reader_one_current)
    subscription.unsubscribed_at = 1.day.ago

    freeze_time do
      assert_changes -> { subscription.reload.unsubscribed_at }, to: Time.current do
        assert subscription.unsubscribe
      end
    end
  end

  test "does not allow moving active subscriptions back to pending confirmation" do
    subscription = subscriptions(:reader_one_current)
    subscription.status = "pending_confirmation"
    subscription.confirmed_at = nil

    assert_not subscription.valid?
    assert subscription.errors.of_kind?(:status, "cannot be moved from 'active' to 'pending_confirmation'")
  end

  test "does not allow reactivating unsubscribed subscriptions" do
    subscription = subscriptions(:reader_four_current_unsubscribed)
    subscription.status = "active"
    subscription.unsubscribed_at = nil

    assert_not subscription.valid?
    assert subscription.errors.of_kind?(:status, "cannot be moved from 'unsubscribed' to 'active'")
  end

  test "db constraint only allows one current subscription per subscriber" do
    subscriber = subscribers(:reader_one)

    assert_db_constraint_violation do
      Subscription.new(subscriber: subscriber, status: "pending_confirmation").save!(validate: false)
    end
  end

  test "db constraint enforces valid status" do
    subscriber = subscribers(:reader_without_subscription)

    assert_db_constraint_violation do
      Subscription.new(subscriber: subscriber, status: "not-a-status").save!(validate: false)
    end
  end

  test "db constraint requires confirmed at for active subscriptions" do
    subscriber = subscribers(:reader_without_subscription)

    assert_db_constraint_violation do
      Subscription.new(subscriber: subscriber, status: "active", confirmed_at: nil).save!(validate: false)
    end
  end

  test "db constraint requires blank unsubscribed at for active subscriptions" do
    subscriber = subscribers(:reader_without_subscription)

    assert_db_constraint_violation do
      Subscription.new(
        subscriber: subscriber,
        status: "active",
        confirmed_at: Time.current,
        unsubscribed_at: Time.current
      ).save!(validate: false)
    end
  end

  test "db constraint requires blank lifecycle timestamps for pending subscriptions" do
    subscriber = subscribers(:reader_without_subscription)

    assert_db_constraint_violation do
      Subscription.new(
        subscriber: subscriber,
        status: "pending_confirmation",
        confirmed_at: Time.current,
        unsubscribed_at: Time.current
      ).save!(validate: false)
    end
  end

  test "db constraint requires unsubscribed at for unsubscribed subscriptions" do
    subscriber = subscribers(:reader_without_subscription)

    assert_db_constraint_violation do
      Subscription.new(subscriber: subscriber, status: "unsubscribed", unsubscribed_at: nil).save!(validate: false)
    end
  end

  test "db constraint rejects confirmed at for pending subscriptions" do
    subscriber = subscribers(:reader_without_subscription)

    assert_db_constraint_violation do
      Subscription.new(
        subscriber: subscriber,
        status: "pending_confirmation",
        confirmed_at: Time.current
      ).save!(validate: false)
    end
  end

  private
    def assert_db_constraint_violation
      assert_raises(ActiveRecord::StatementInvalid, ActiveRecord::RecordNotUnique) { yield }
    end
end
