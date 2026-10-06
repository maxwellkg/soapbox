class Subscriber < ApplicationRecord
  include Searchable::Model
  include Unsubscribable

  has_many :subscriptions, dependent: :destroy, inverse_of: :subscriber, autosave: true

  after_initialize :ensure_latest_subscription, if: :new_record?

  # A subscriber's status is always the status of its most recent subscription,
  # See fuller explanation in note below on .latest_subscription
  scope :with_latest_subscription, -> {
    joins(:subscriptions).where(<<~SQL)
      subscriptions.id = (
        SELECT MAX(latest_subscriptions.id)
        FROM subscriptions latest_subscriptions
        WHERE latest_subscriptions.subscriber_id = subscribers.id
      )
    SQL
  }

  scope :active, -> { with_latest_subscription.merge(Subscription.active) }
  scope :pending_confirmation, -> { with_latest_subscription.merge(Subscription.pending_confirmation) }
  scope :unsubscribed, -> { with_latest_subscription.merge(Subscription.unsubscribed) }

  scope :for_status, ->(status) do
    return all if status.blank?

    status.to_s.in?(Subscription::STATUSES) ? public_send(status) : none
  end

  normalizes :email_address, with: ->(email) { email.strip.downcase }

  validates :email_address,
            presence: true,
            uniqueness: true,
            format: { with: URI::MailTo::EMAIL_REGEXP }

  # opt-in is tied to a specific email address, so don't allow for changes to it
  validate :email_address_is_immutable, unless: :new_record?

  basic_search_on :email_address

  delegate :status, :active?, :pending_confirmation?, :unsubscribed?, to: :latest_subscription

  # A subscriber's status is always the status of its most recent subscription,
  # read through the :subscriptions association rather than through a special association
  # designed to track the latest subscription
  #
  # The direct association version — has_one :current_subscription, -> { current } —
  # was tried and does not work here. Assigning a new record to a has_one relationship replaces
  # the previous record's foreign key. Previous subscriptions should remain related to the Subscriber,
  # though, so this setup doesn't work for our purposes. Additionally, Worse, two associations over
  # the same table cache independently: creating through :subscriptions leaves :current_subscription
  # holding a stale row — and a second object for that row — until an explicit reload
  #
  # Reading through :subscriptions keeps one cache and one source of truth. The
  # Note: .with_latest_subscription is the same rule expressed in SQL.
  def latest_subscription
    if new_record? || association(:subscriptions).loaded?
      subscriptions.max_by(&:id)
    else
      subscriptions.order(id: :desc).first
    end
  end

  def subscribe
    if new_record?
      save
    else
      if pending_confirmation?
        latest_subscription.send_confirmation
      elsif active?
        true
      else
        subscriptions.create.persisted?
      end
    end
  end

  def unsubscribe
    return true if unsubscribed?

    latest_subscription.unsubscribe
  end

  private
    def email_address_is_immutable
      errors.add(:email_address, :immutable) if will_save_change_to_email_address?
    end

    def ensure_latest_subscription
      latest_subscription || subscriptions.build
    end
end
