class Post::StartEmailsJob < ApplicationJob
  queue_as :default

  def perform(post:, key:)
    post.send(:initiate_emails_using_key, key: key)
  end
end
