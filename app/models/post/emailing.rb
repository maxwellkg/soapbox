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

    before_validation :update_start_emails_job_key, if: -> { will_save_change_to_email_status? && !email_status_initiated? }

    after_commit :enqueue_start_emails_job, if: -> { saved_change_to_email_status?(to: "pending") }
  end

  def can_start_emails?
    email_status_not_started? && published?
  end

  def can_stop_emails?
    email_status_pending?
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

    def generate_new_start_emails_job_key
      _new_start_emails_job_key if email_status_pending?
    end

    def _new_start_emails_job_key
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

    def initiate_emails_using_key(key:)
      # The job key works as a cancellation token so stale delayed jobs no-op
      # after a stop/restart cycle changes `start_emails_job_key`.
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
