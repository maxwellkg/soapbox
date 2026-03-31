require "test_helper"

class Post::EmailingTest < ActiveSupport::TestCase
  test "must have a valid email status" do
    post = Post.new
    post.email_status = "foobar"
    post.valid?

    assert post.errors.of_kind?(:email_status, :inclusion)
  end

  test "must have an email status" do
    post = Post.new
    post.email_status = nil
    post.valid?

    assert post.errors.of_kind?(:email_status, :inclusion)
  end

  test "cannot have start_emails_job_key if email status is 'not_started'" do
    post = Post.new(start_emails_job_key: SecureRandom.uuid)
    post.valid?

    assert post.errors.of_kind?(:start_emails_job_key, :present)
  end

  test "start_emails_job_key must be unique for non-not_started statuses" do
    pending = posts(:pending_email)
    emailed = posts(:emailed)

    emailed.start_emails_job_key = pending.start_emails_job_key
    emailed.valid?

    assert emailed.errors.of_kind?(:start_emails_job_key, :taken)
  end

  test "cannot make email status 'pending' unless published" do
    post = posts(:draft)
    post.email_status = "pending"
    post.valid?

    assert post.errors.of_kind?(:email_status, :invalid)
    assert_includes post.errors[:email_status], "cannot be moved to pending unless published"
  end

  test "cannot change email status once 'initiated'" do
    post = posts(:emailed)
    post.email_status = "pending"
    post.valid?

    assert post.errors.of_kind?(:email_status, :invalid)
    assert_includes post.errors[:email_status], "cannot be moved once initiated"
  end

  test "email status can only be changed to 'initiated' from 'pending'" do
    post = posts(:published)
    post.email_status = "initiated"
    post.valid?

    assert post.errors.of_kind?(:email_status, :invalid)
    assert_includes post.errors[:email_status], "can only be moved to 'initiated' if was previously 'pending'"
  end

  test "it determines whether it can start emails" do
    published = posts(:published)

    published.email_status = "pending"
    assert_not published.can_start_emails?

    published.email_status = "initiated"
    assert_not published.can_start_emails?

    published.email_status = "not_started"
    assert published.can_start_emails?

    published.status = "draft"
    assert_not published.can_start_emails?
  end

  test "setting the start emails job key" do
    post = posts(:pending_email)

    assert_changes -> { post.start_emails_job_key } do
      post.send(:update_start_emails_job_key)
    end

    assert_changes -> { post.start_emails_job_key }, to: nil do
      post.email_status = "not_started"
      post.send(:update_start_emails_job_key)
    end

    post.email_status = "initiated"
    assert post.send(:update_start_emails_job_key).nil?
  end

  test "it automatically updates the start emails job key before validation" do
    post = posts(:published)
    post.email_status = "pending"

    assert_changes -> { post.start_emails_job_key } do
      post.valid?
    end

    pending = posts(:pending_email)
    pending.email_status = "initiated"

    assert_no_changes -> { post.start_emails_job_key } do
      pending.valid?
    end
  end

  test "starts emails via domain command" do
    post = posts(:published)

    assert_changes -> { post.reload.email_status }, from: "not_started", to: "pending" do
      assert post.start_emails!
    end
  end

  test "stops emails via domain command" do
    post = posts(:pending_email)

    assert_changes -> { post.reload.email_status }, from: "pending", to: "not_started" do
      assert post.stop_emails!
    end
  end

  test "enqueues a job to start the emails" do
    post = posts(:published)
    job_key = post.start_emails_job_key

    assert_enqueued_with job: Post::StartEmailsJob, args: [ { post: post, key: job_key } ] do
      post.send(:enqueue_start_emails_job)
    end
  end

  test "initiate_emails_using_key initiates when key matches" do
    post = posts(:pending_email)
    matching_key = post.start_emails_job_key
    num_active_subscriptions = Subscription.active.count

    assert_enqueued_emails 0

    assert_changes -> { post.emails.count }, from: 0, to: num_active_subscriptions do
      assert_changes -> { post.email_status }, from: "pending", to: "initiated" do
        post.send(:initiate_emails_using_key, key: matching_key)
      end
    end

    assert_enqueued_emails num_active_subscriptions
  end

  test "initiate_emails_using_key does nothing when key does not match" do
    post = posts(:pending_email)

    assert_no_changes -> { post.emails.count } do
      assert_no_changes -> { post.email_status } do
        post.send(:initiate_emails_using_key, key: "anInvalidKey")
      end
    end

    assert_enqueued_emails 0
  end

  test "initiate_emails_using_key raises when key matches and status is not pending" do
    post = posts(:emailed)

    assert_raises(RuntimeError, /'pending'/) do
      post.send(:initiate_emails_using_key, key: post.start_emails_job_key)
    end
  end

  test "cannot initiate emails when status is not pending" do
    post = posts(:published)

    assert_raises match: /'pending'/ do
      post.send(:initiate_emails)
    end
  end

  test "initiating emails" do
    post = posts(:pending_email)
    num_active_subscriptions = Subscription.active.count

    assert_enqueued_emails 0

    assert_changes -> { post.emails.count }, from: 0, to: num_active_subscriptions do
      assert_changes -> { post.email_status }, from: "pending", to: "initiated" do
        post.send(:initiate_emails)
      end
    end

    assert_enqueued_emails num_active_subscriptions
  end

  test "can be unpublished after emails are initiated" do
    post = posts(:emailed)

    assert_nothing_raised { post.draft! }
  end
end
