class PostEmail < ApplicationRecord
  belongs_to :post
  belongs_to :subscription

  validates :post, uniqueness: { scope: :subscription }

  after_create_commit :enqueue_email

  def email_to
    subscription.subscriber.email_address
  end

  def email_subject
    post.title
  end

  private
    def enqueue_email
      PostEmailsMailer
        .with(post_email: self)
        .post_email
        .deliver_later
    end
end
