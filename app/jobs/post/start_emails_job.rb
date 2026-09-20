class Post::StartEmailsJob < ApplicationJob
  queue_as :default

  # Post::StartEmailsJob is a delayed callback into the Post, not an
  # independent service. After the one-minute wait, it calls back to ask the
  # Post whether email delivery should still begin. The job uses .send to
  # invoke a private method because starting emails is not a public operation:
  # the correct public API is changing email_status through start_emails or
  # stop_emails. The private method exists solely for this delayed callback,
  # where the job has already validated the job key before proceeding.
  def perform(post:, key:)
    post.send(:initiate_emails_using_key, key: key)
  end
end
