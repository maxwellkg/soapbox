module Subscription::Lifecycle
  extend ActiveSupport::Concern

  class_methods do
    def find_by_confirmation_token!(token)
      find_by_confirmation_token(token) ||
        raise(ActiveRecord::RecordNotFound.new("Could not find Subscription with confirmation token = #{token}"))
    end

    def find_by_confirmation_token(token)
      find_by_token_for(:confirmation, token)
    end
  end

  included do
    STATUSES = %w[ pending_confirmation active unsubscribed ]

    enum :status, STATUSES.index_with(&:itself), default: "pending_confirmation", validate: true

    generates_token_for :confirmation do
      status
    end

    scope :current, -> { where(status: %w[ pending_confirmation active ]) }

    validates :subscriber_id, uniqueness: { conditions: -> { current } }, if: :current?

    validate :validate_initial_status, on: :create
    validate :validate_transition, if: :updating_status?
    validate :validate_timestamp_consistency

    before_validation :synchronize_lifecycle_timestamps, if: -> { activating? || unsubscribing? }
  end

  def confirmation_token
    generate_token_for(:confirmation)
  end

  def current?
    pending_confirmation? || active?
  end

  def confirm
    return true if active?
    return false unless pending_confirmation?

    update(status: "active")
  end

  def unsubscribe
    return true if unsubscribed?
    return false unless current?

    update(status: "unsubscribed")
  end

  def send_confirmation
    return false unless pending_confirmation?

    send_confirmation_email
    true
  end

  private
    def validate_transition
      errors.add(:status, message: "cannot be moved from '#{status_in_database}' to '#{status}'") if disallowed_transition?
    end

    def updating_status?
      persisted? && will_save_change_to_status?
    end

    def validate_initial_status
      errors.add(:status, message: "must start as 'pending_confirmation'") unless pending_confirmation?
    end

    def disallowed_transition?
      !allowed_transition?
    end

    def allowed_transition?
      will_save_change_to_status?(from: "pending_confirmation", to: "active") ||
        will_save_change_to_status?(from: "pending_confirmation", to: "unsubscribed") ||
        will_save_change_to_status?(from: "active", to: "unsubscribed")
    end

    def validate_timestamp_consistency
      validate_pending_confirmation_timestamps if pending_confirmation?
      validate_active_timestamps if active?
      validate_unsubscribed_timestamps if unsubscribed?
    end

    def validate_pending_confirmation_timestamps
      errors.add(:confirmed_at, message: "must be blank while subscription is pending confirmation") if confirmed_at.present?
      errors.add(:unsubscribed_at, message: "must be blank while subscription is pending confirmation") if unsubscribed_at.present?
    end

    def validate_active_timestamps
      errors.add(:confirmed_at, :blank) if confirmed_at.blank?
      errors.add(:unsubscribed_at, message: "must be blank while subscription is active") if unsubscribed_at.present?
    end

    def validate_unsubscribed_timestamps
      errors.add(:unsubscribed_at, :blank) if unsubscribed_at.blank?
    end

    def synchronize_lifecycle_timestamps
      set_confirmed_at if activating?
      set_unsubscribed_at if unsubscribing?
    end

    def activating?
      will_save_change_to_status?(to: "active")
    end

    def unsubscribing?
      will_save_change_to_status?(to: "unsubscribed")
    end

    def set_confirmed_at
      self.confirmed_at = Time.current
    end

    def set_unsubscribed_at
      self.unsubscribed_at = Time.current
    end
end
