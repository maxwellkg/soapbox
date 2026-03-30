class CreateSubscriptions < ActiveRecord::Migration[8.1]
  def change
    create_table :subscriptions do |t|
      t.references :subscriber, null: false, foreign_key: true
      t.boolean :active, null: false, default: false
      t.date :start_date
      t.date :end_date

      t.timestamps
    end

    add_index :subscriptions,
              :subscriber_id,
              unique: true,
              where: "active = 1",
              name: "index_subscriptions_on_subscriber_id_when_active"

    add_check_constraint :subscriptions,
                         "end_date IS NULL OR start_date IS NULL OR end_date >= start_date",
                         name: "subscriptions_end_date_after_start_date"

    add_check_constraint :subscriptions,
                         "active = 0 OR start_date IS NOT NULL",
                         name: "subscriptions_active_requires_start_date"

    add_check_constraint :subscriptions,
                         "active = 0 OR end_date IS NULL",
                         name: "subscriptions_active_requires_blank_end_date"
  end
end
