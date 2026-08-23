class PostEmail < ApplicationRecord
  belongs_to :post
  belongs_to :subscription

  validates :post, uniqueness: { scope: :subscription }

  after_create_commit :enqueue_email

  private
    def enqueue_email
      PostMailer
        .with(post:, subscriber: subscription.subscriber)
        .post_email
        .deliver_later
    end
end
