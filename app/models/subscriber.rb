class Subscriber < ApplicationRecord
  include Subscriber::Unsubscribable

  STATUSES = %w[ active inactive ]

  has_many :subscriptions, dependent: :destroy, inverse_of: :subscriber
  has_one :active_subscription, -> { active }, class_name: "Subscription"

  scope :active, -> { where.associated(:active_subscription) }
  scope :inactive, -> { where.missing(:active_subscription) }

  scope :for_status, ->(status) do
    return all if status.blank?

    status.to_s.in?(STATUSES) ? public_send(status) : none
  end

  normalizes :email_address, with: ->(email) { email.strip.downcase }

  validates :email_address,
            presence: true,
            uniqueness: true,
            format: { with: URI::MailTo::EMAIL_REGEXP }

  def active?
    active_subscription.present?
  end

  def inactive?
    !active?
  end

  def activate
    return true if active?

    ensure_active_subscription
    save
  end

  def deactivate
    return true if inactive?

    deactivated_successfully = active_subscription.deactivate
    reset_active_subscription

    deactivated_successfully
  end

  private
    def ensure_active_subscription
      active_subscription || build_active_subscription(active: true)
    end
end
