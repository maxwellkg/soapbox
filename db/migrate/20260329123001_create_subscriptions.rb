class CreateSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :subscriptions do |t|
      t.references :subscriber, null: false, foreign_key: true
      t.string :status, null: false
      t.datetime :confirmed_at
      t.datetime :unsubscribed_at

      t.timestamps
    end

    add_index :subscriptions,
              :subscriber_id,
              unique: true,
              where: "status IN ('pending_confirmation', 'active')",
              name: "index_subscriptions_on_subscriber_id_when_current"

    add_check_constraint :subscriptions,
                         "status IN ('pending_confirmation', 'active', 'unsubscribed')",
                         name: "subscriptions_status_check"

    add_check_constraint :subscriptions,
                         "status <> 'pending_confirmation' OR (confirmed_at IS NULL AND unsubscribed_at IS NULL)",
                         name: "subscriptions_pending_confirmation_timestamps_check"

    add_check_constraint :subscriptions,
                         "status <> 'active' OR (confirmed_at IS NOT NULL AND unsubscribed_at IS NULL)",
                         name: "subscriptions_active_timestamps_check"

    add_check_constraint :subscriptions,
                         "status <> 'unsubscribed' OR unsubscribed_at IS NOT NULL",
                         name: "subscriptions_unsubscribed_timestamps_check"

    add_check_constraint :subscriptions,
                         "(confirmed_at IS NULL OR status IN ('active', 'unsubscribed')) AND (unsubscribed_at IS NULL OR status = 'unsubscribed')",
                         name: "subscriptions_lifecycle_timestamps_match_status"
  end
end
