# A post's email delivery follows this lifecycle. When an author starts delivery
# for a published post, Soapbox generates a unique job key, moves email_status
# to pending, and enqueues Post::StartEmailsJob to run after a one-minute wait.
#
# This delay creates a cancellation window: the author can stop delivery during
# that minute by changing email_status back to not_started, which clears the job
# key. The post's email_status and start_emails_job_key together determine
# whether the delayed job should proceed or abort.
#
#   not_started
#        │
#        │ start_emails!
#        │ generate key; enqueue job with wait: 1.minute
#        ▼
#      pending ─────────────── stop_emails! ───────────────▶ not_started
#        │                                                   clear key
#        │
#        │ delayed job runs with matching key
#        │ create PostEmail records; mark initiated
#        ▼
#     initiated
#
#   A delayed job with a missing or different key is stale and does nothing.
#   This can happen after cancellation (author changed email_status back to
#   not_started) or after a later restart (new pending delivery with a new key).
#   The job-key check prevents duplicate or unwanted emails from being sent.

module Post::Emailing
  extend ActiveSupport::Concern

  EMAIL_START_WAIT_TIME = 1.minute

  included do
    has_many :emails, class_name: "PostEmail", dependent: :destroy

    enum :email_status, %w[ not_started pending initiated ].index_with(&:itself), prefix: true, validate: true

    validates :start_emails_job_key, absence: true, if: :email_status_not_started?

    validates :start_emails_job_key,
              presence: true,
              uniqueness: { conditions: -> { where.not(email_status: "not_started") } },
              unless: :email_status_not_started?

    with_options if: :will_save_change_to_email_status? do
      validate :email_status_cannot_be_moved_to_pending_unless_published
      validate :email_status_cannot_be_changed_once_initiated
      validate :email_status_can_only_be_changed_to_initiated_from_pending
    end

    before_validation :update_start_emails_job_key, if: :will_save_change_to_email_status?

    after_commit :enqueue_start_emails_job, if: -> { saved_change_to_email_status?(to: "pending") }
    after_update_commit :broadcast_refresh, if: :saved_change_to_email_status?
  end

  def can_start_emails?
    email_status_not_started? && published?
  end

  def can_stop_emails?
    email_status_pending?
  end

  def pending_emails_were_stopped?
    saved_change_to_email_status?(from: "pending", to: "not_started")
  end

  def start_emails!
    update(email_status: "pending")
  end

  def stop_emails!
    update(email_status: "not_started")
  end

  private
    def email_status_cannot_be_moved_to_pending_unless_published
      if will_save_change_to_email_status?(to: "pending") && !published?
        errors.add(:email_status, message: "cannot be moved to pending unless published")
      end
    end

    def email_status_cannot_be_changed_once_initiated
      if will_save_change_to_email_status?(from: "initiated")
        errors.add(:email_status, message: "cannot be moved once initiated")
      end
    end

    def email_status_can_only_be_changed_to_initiated_from_pending
      if will_save_change_to_email_status?(to: "initiated") && !will_save_change_to_email_status?(from: "pending")
        errors.add(:email_status, message: "can only be moved to 'initiated' if was previously 'pending'")
      end
    end

    def update_start_emails_job_key
      return if email_status_initiated?

      self.start_emails_job_key = generate_new_start_emails_job_key
    end

    # Active Job does not support cancelling enqueued jobs. The job key serves as
    # an application-level cancellation token: when the job runs, it checks whether
    # the key it carries still matches the post's current key. A mismatch (or a
    # cleared key) means the author cancelled or restarted delivery, so the job
    # must abort to prevent unwanted emails.
    def generate_new_start_emails_job_key
      new_start_emails_job_key if email_status_pending?
    end

    def new_start_emails_job_key
      SecureRandom.uuid
    end

    def email_job_key_matches?(key)
      key == start_emails_job_key
    end

    def enqueue_start_emails_job
      Post::StartEmailsJob
        .set(wait: EMAIL_START_WAIT_TIME)
        .perform_later(post: self, key: start_emails_job_key)
    end

    # The job key validates that this delayed work is still authorized. A stale
    # job (key was cleared by stop_emails! or replaced by a later restart) must
    # do nothing: running would create PostEmail records for a delivery the
    # author explicitly cancelled, potentially sending duplicate emails to readers.
    def initiate_emails_using_key(key:)
      initiate_emails if email_job_key_matches?(key)
    end

    def initiate_emails
      raise "Can only initiate emails when email_status is 'pending'" unless email_status_pending?

      build_emails_for_active_subscriptions
      email_status_initiated!
    end

    def build_emails_for_active_subscriptions
      Subscription.active.find_each do |subscription|
        emails.build(subscription: subscription)
      end
    end
end
