class Subscription < ApplicationRecord
  belongs_to :subscriber, touch: true, inverse_of: :subscriptions

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }

  validates :subscriber_id, uniqueness: { conditions: -> { active } }, if: :active?
  validates :start_date, presence: true, if: -> { active? || end_date.present? }
  validate :validate_end_date_absence_when_active, if: :active?
  validate :cannot_be_reactivated, if: :will_reactivate?
  validate :validate_end_date, if: :has_start_and_end_date?

  before_validation :set_start_date_today, if: :missing_start_date_on_activation?
  before_validation :set_end_date_today, if: :missing_end_date_on_deactivation?

  def inactive?
    !active?
  end

  def deactivate
    update(active: false)
  end

  private
    def has_start_and_end_date?
      start_date.present? && end_date.present?
    end

    def validate_end_date
      errors.add(:end_date, message: "must be greater or equal to start date") if end_date < start_date
    end

    def validate_end_date_absence_when_active
      errors.add(:end_date, message: "must be blank when subscription is active") if end_date.present?
    end

    def cannot_be_reactivated
      errors.add(:active, message: "cannot reactivate an ended subscription")
    end

    def will_reactivate?
      # Ended periods are immutable history. Re-subscribing should create a new
      # active period instead of reopening one with an `end_date`.
      will_activate? && end_date_in_database.present?
    end

    def will_activate?
      will_save_change_to_active?(to: true)
    end

    def will_deactivate?
      will_save_change_to_active?(to: false)
    end

    def missing_end_date_on_deactivation?
      will_deactivate? && end_date.blank?
    end

    def set_end_date_today
      self.end_date = Date.current
    end

    def missing_start_date_on_activation?
      will_activate? && start_date.blank?
    end

    def set_start_date_today
      self.start_date = Date.current
    end
end
