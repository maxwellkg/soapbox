require "test_helper"

class Post::StartEmailsJobTest < ActiveJob::TestCase
  test "initiates emails" do
    post = posts(:pending_email)
    key = post.start_emails_job_key
    Post::StartEmailsJob.perform_now(post: post, key: key)
    post.reload

    assert post.email_status_initiated?
  end

  test "aborts if key doesn't match" do
    post = posts(:pending_email)
    Post::StartEmailsJob.perform_now(post: post, key: "anInvalidKey")
    post.reload

    assert_not post.email_status_initiated?
  end
end
