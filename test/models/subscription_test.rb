require "test_helper"

class SubscriptionTest < ActiveSupport::TestCase
  test "is invalid without a subscriber" do
    subscription = Subscription.new(active: false)
    assert_not subscription.valid?

    assert subscription.errors.of_kind?(:subscriber, :blank)

    subscription.subscriber = subscribers(:reader_without_subscription)

    assert subscription.valid?
    assert_not subscription.errors.of_kind?(:subscriber, :blank)
  end

  test "only allows one active subscription per subscriber" do
    existing = subscriptions(:reader_two_active)

    new_subscription = existing.subscriber.subscriptions.build(active: true)
    assert_not new_subscription.valid?

    assert new_subscription.errors.of_kind?(:subscriber_id, :taken)

    new_subscription.active = false
    assert new_subscription.valid?

    assert_not new_subscription.errors.of_kind?(:subscriber_id, :taken)
  end

  test "requires start date if active" do
    subscription = subscriptions(:reader_one_active)
    subscription.start_date = nil
    assert_not subscription.valid?

    assert subscription.errors.of_kind?(:start_date, :blank)

    subscription.start_date = Date.current

    assert subscription.valid?
    assert_not subscription.errors.of_kind?(:start_date, :blank)
  end

  test "sets start date when activating" do
    subscription = subscriptions(:reader_four_inactive)
    subscription.active = true

    freeze_time do
      assert_changes -> { subscription.start_date }, from: nil, to: Date.current do
        subscription.valid?
      end
    end
  end

  test "does not overwrite existing start date when activating" do
    subscription = subscriptions(:reader_four_inactive)
    subscription.active = true
    subscription.start_date = Date.yesterday

    assert_no_changes -> { subscription.start_date } do
      subscription.valid?
    end
  end

  test "sets end date when deactivating" do
    subscription = subscriptions(:reader_one_active)
    subscription.active = false

    freeze_time do
      assert_changes -> { subscription.end_date }, from: nil, to: Date.current do
        subscription.valid?
      end
    end
  end

  test "does not overwrite existing end date when deactivating" do
    subscription = subscriptions(:reader_one_active)
    subscription.active = false
    subscription.end_date = Date.yesterday

    assert_no_changes -> { subscription.end_date } do
      subscription.valid?
    end
  end

  test "is invalid when end date is before start date" do
    subscription = Subscription.new(
      subscriber: subscribers(:reader_without_subscription),
      active: false,
      start_date: Date.current,
      end_date: Date.yesterday
    )

    assert_not subscription.valid?

    assert subscription.errors.of_kind?(:end_date, "must be greater or equal to start date")

    subscription.end_date = subscription.start_date

    assert subscription.valid?
    assert_not subscription.errors.of_kind?(:end_date, "must be greater or equal to start date")
  end

  test "is invalid when active subscription has an end date" do
    subscription = Subscription.new(
      subscriber: subscribers(:reader_without_subscription),
      active: true,
      end_date: Date.current
    )

    assert_not subscription.valid?

    assert subscription.errors.of_kind?(:end_date, "must be blank when subscription is active")

    subscription.end_date = nil

    assert subscription.valid?
    assert_not subscription.errors.of_kind?(:end_date, "must be blank when subscription is active")
  end

  test "does not allow reactivating an ended subscription" do
    subscription = subscriptions(:reader_four_ended_history)

    subscription.active = true
    subscription.end_date = nil

    assert_not subscription.valid?
    assert subscription.errors.of_kind?(:active, "cannot reactivate an ended subscription")

    replacement = Subscription.new(
      subscriber: subscribers(:reader_without_subscription),
      active: true,
      start_date: Date.current
    )

    assert replacement.valid?
    assert_not replacement.errors.of_kind?(:active, "cannot reactivate an ended subscription")
  end

  test "scope for active" do
    active_subscriptions = [
      subscriptions(:reader_one_active),
      subscriptions(:reader_two_active),
      subscriptions(:reader_three_active),
      subscriptions(:reader_four_active)
    ]

    assert_equal active_subscriptions.map(&:id).sort, Subscription.active.map(&:id).sort
  end

  test "scope for inactive" do
    inactive_subscriptions = [
      subscriptions(:reader_three_inactive_history),
      subscriptions(:reader_four_inactive),
      subscriptions(:reader_four_ended_history)
    ]

    assert_equal inactive_subscriptions.map(&:id).sort, Subscription.inactive.map(&:id).sort
  end

  test "db constraint only allows one active subscription per subscriber" do
    subscriber = subscribers(:reader_one)

    assert_db_constraint_violation do
      Subscription.new(subscriber: subscriber, active: true, start_date: Date.current).save!(validate: false)
    end
  end

  test "db constraint requires start date for active subscriptions" do
    subscriber = subscribers(:reader_without_subscription)

    assert_db_constraint_violation do
      Subscription.new(subscriber: subscriber, active: true, start_date: nil).save!(validate: false)
    end
  end

  test "db constraint requires blank end date for active subscriptions" do
    subscriber = subscribers(:reader_without_subscription)

    assert_db_constraint_violation do
      Subscription.new(
        subscriber: subscriber,
        active: true,
        start_date: Date.current,
        end_date: Date.current
      ).save!(validate: false)
    end
  end

  test "db constraint enforces end date is after or equal to start date" do
    subscriber = subscribers(:reader_without_subscription)

    assert_db_constraint_violation do
      Subscription.new(
        subscriber: subscriber,
        active: false,
        start_date: Date.current,
        end_date: Date.yesterday
      ).save!(validate: false)
    end
  end

  private
    def assert_db_constraint_violation
      assert_raises(ActiveRecord::StatementInvalid, ActiveRecord::RecordNotUnique) { yield }
    end
end
