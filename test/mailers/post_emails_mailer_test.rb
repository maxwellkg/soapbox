require "test_helper"

class PostEmailsMailerTest < ActionMailer::TestCase
  test "email includes unsubscribe link" do
    post_email = post_emails(:reader_one_email)
    email = PostEmailsMailer.with(post_email: post_email).post_email

    unsubscribe_path = "/subscribers/#{post_email.subscription.subscriber.unsubscribe_token}/unsubscribe"
    assert_includes email.body.raw_source, unsubscribe_path
  end

  test "email sets list_unsubscribe header" do
    post_email = post_emails(:reader_one_email)
    email = PostEmailsMailer.with(post_email: post_email).post_email

    assert_not_nil email.header["List-Unsubscribe"]
    unsubscribe_path = "/subscribers/#{post_email.subscription.subscriber.unsubscribe_token}/unsubscribe"
    assert_includes email.header["List-Unsubscribe"].value, unsubscribe_path
  end
end
