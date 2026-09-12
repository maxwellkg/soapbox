class Subscriber < ApplicationRecord
  include Searchable::Model
  include Subscriber::Unsubscribable

  has_many :subscriptions, dependent: :destroy, inverse_of: :subscriber, autosave: true

  after_initialize :ensure_latest_subscription, if: :new_record?

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

  basic_search_on :email_address

  delegate :status, :active?, :pending_confirmation?, :unsubscribed?, to: :latest_subscription

  # A subscriber's status is always the status of its most recent subscription,
  # read through the :subscriptions association rather than through one of its own.
  #
  # The direct spelling of this — has_one :current_subscription, -> { current } —
  # was tried and does not work here. Assigning to a has_one nullifies the replaced
  # record's foreign key, and an ended subscription is a historical fact that must
  # never be detached or rewritten. Worse, two associations over the same table
  # cache independently: creating through :subscriptions leaves :current_subscription
  # holding a stale row — and a second object for that row — until an explicit
  # reload at every call site, which is exactly the caller discipline this model
  # exists to remove.
  #
  # Reading through :subscriptions keeps one cache and one source of truth. The
  # branch below is what makes that hold whether or not the association is already
  # loaded, and .with_latest_subscription is the same rule expressed in SQL.
  def latest_subscription
    if new_record? || association(:subscriptions).loaded?
      subscriptions.max_by(&:id)
    else
      subscriptions.order(id: :desc).first
    end
  end

  def subscribe
    if pending_confirmation?
      latest_subscription.send_confirmation
    elsif active?
      true
    else
      subscriptions.create.persisted?
    end
  end

  def unsubscribe
    return true if unsubscribed?

    latest_subscription.unsubscribe
  end

  private
    def ensure_latest_subscription
      latest_subscription || subscriptions.build
    end
end
