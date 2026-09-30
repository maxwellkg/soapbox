class PostEmail < ApplicationRecord
  belongs_to :post
  belongs_to :subscription

  validates :post, uniqueness: { scope: :subscription }
  validate :subscription_is_active

  after_create_commit :enqueue_email

  private
    def subscription_is_active
      errors.add(:subscription, "must be active") if subscription.present? && !subscription.active?
    end

    def enqueue_email
      PostMailer
        .with(post:, subscriber: subscription.subscriber)
        .post_email
        .deliver_later
    end
end
