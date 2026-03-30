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

  test "knows whether it has an active subscription" do
    active = subscribers(:reader_three)

    assert active.active?
    assert_not active.inactive?

    inactive = subscribers(:reader_four)

    assert_not inactive.active?
    assert inactive.inactive?
  end

  test "deactivates" do
    active = subscribers(:reader_three)

    assert_changes -> { active.active? }, from: true, to: false do
      assert_changes -> { active.active_subscription }, to: nil do
        assert active.deactivate
      end
    end

    inactive = subscribers(:reader_four)

    assert_no_changes -> { inactive.updated_at } do
      assert inactive.deactivate
    end
  end

  test "active subscriber activate is idempotent" do
    subscriber = subscribers(:reader_one)

    assert_no_changes -> { Subscription.where(subscriber_id: subscriber.id).count } do
      assert subscriber.activate
    end
  end

  test "inactive subscriber deactivate is idempotent" do
    subscriber = subscribers(:reader_without_subscription)

    assert_no_changes -> { subscriber.updated_at } do
      assert subscriber.deactivate
    end
  end

  test "scopes to active subscribers" do
    active = %i[reader_one reader_two reader_three].map { |key| subscribers(key) }

    assert_equal active.map(&:id).sort, Subscriber.active.pluck(:id).sort
  end

  test "scopes to inactive subscribers" do
    inactive = %i[reader_four reader_without_subscription].map { |key| subscribers(key) }

    assert_equal inactive.map(&:id).sort, Subscriber.inactive.pluck(:id).sort
  end

  test "for_status returns matching scope" do
    assert_equal Subscriber.active.to_a, Subscriber.for_status(:active).to_a
    assert_equal Subscriber.inactive.to_a, Subscriber.for_status("inactive").to_a
    assert_equal [], Subscriber.for_status("unknown").to_a
    assert_equal Subscriber.all.to_a, Subscriber.for_status(nil).to_a
  end

  test "finds related subscriptions" do
    subscriber = subscribers(:reader_three)
    subscriptions = [ subscriptions(:reader_three_active), subscriptions(:reader_three_inactive_history) ]

    assert_equal subscriptions(:reader_three_active), subscriber.active_subscription
    assert_equal subscriptions.map(&:id).sort, subscriber.subscriptions.pluck(:id).sort
  end

  test "activates an inactive subscriber" do
    subscriber = subscribers(:reader_without_subscription)

    assert_changes -> { subscriber.active? }, from: false, to: true do
      assert_difference -> { Subscription.where(subscriber_id: subscriber.id).count }, 1 do
        assert subscriber.activate
      end
    end
  end

  test "can re-subscribe after deactivation by creating a new subscription period" do
    subscriber = subscribers(:reader_without_subscription)

    assert_difference -> { Subscription.where(subscriber_id: subscriber.id).count }, 1 do
      assert subscriber.activate
    end

    first_active_subscription = subscriber.reload.active_subscription

    assert subscriber.deactivate

    first_active_subscription.reload
    assert_not first_active_subscription.active?
    assert_not_nil first_active_subscription.end_date

    assert_difference -> { Subscription.where(subscriber_id: subscriber.id).count }, 1 do
      assert subscriber.activate
    end

    second_active_subscription = subscriber.reload.active_subscription

    assert second_active_subscription.active?
    assert_not_nil second_active_subscription.start_date
    assert_nil second_active_subscription.end_date
    assert_not_equal first_active_subscription.id, second_active_subscription.id
    assert_not first_active_subscription.reload.active?
  end

  test "activate returns false and stays inactive when subscriber is invalid" do
    subscriber = subscribers(:reader_without_subscription).reload
    subscriber.email_address = nil

    assert_no_changes -> { Subscription.where(subscriber_id: subscriber.id, active: true).count } do
      assert_not subscriber.activate
    end

    assert_not subscriber.reload.active?
  end

  test "supports unsubscribe token finder methods" do
    subscriber = subscribers(:reader_one)
    token = subscriber.unsubscribe_token

    assert_equal subscriber, Subscriber.find_by_unsubscribe_token(token)
    assert_equal subscriber, Subscriber.find_by_unsubscribe_token!(token)
  end

  test "raises when unsubscribe token is invalid" do
    assert_raises(ActiveRecord::RecordNotFound) do
      Subscriber.find_by_unsubscribe_token!("invalid-token")
    end
  end

  test "unsubscribe deactivates subscriber" do
    subscriber = subscribers(:reader_three)

    assert_changes -> { subscriber.reload.active? }, from: true, to: false do
      assert subscriber.unsubscribe
    end
  end
end
