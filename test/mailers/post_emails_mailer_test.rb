require "test_helper"

class PostEmailsMailerTest < ActionMailer::TestCase
  test "email includes unsubscribe link" do
    post_email = post_emails(:reader_one_email)
    email = PostEmailsMailer.with(post_email: post_email).post_email

    unsubscribe_path = "/subscribers/#{post_email.subscription.subscriber.unsubscribe_token}/unsubscribe"
    assert_includes email.html_part.body.decoded, unsubscribe_path
    assert_includes email.text_part.body.decoded, unsubscribe_path
  end

  test "email sets list_unsubscribe header" do
    post_email = post_emails(:reader_one_email)
    email = PostEmailsMailer.with(post_email: post_email).post_email

    assert_not_nil email.header["List-Unsubscribe"]
    unsubscribe_path = "/subscribers/#{post_email.subscription.subscriber.unsubscribe_token}/unsubscribe"
    assert_includes email.header["List-Unsubscribe"].value, unsubscribe_path
  end

  test "email renders html and text parts" do
    post_email = post_emails(:reader_one_email)
    email = PostEmailsMailer.with(post_email: post_email).post_email

    assert_equal "multipart/alternative", email.mime_type
    assert_equal 2, email.parts.size
  end

  test "html part includes blog title and post content" do
    post_email = post_emails(:reader_one_email)
    email = PostEmailsMailer.with(post_email: post_email).post_email
    html = email.html_part.body.decoded

    assert_includes html, Blog.instance!.title
    assert_includes html, post_email.post.title
  end

  test "text part includes read online and unsubscribe links" do
    post_email = post_emails(:reader_one_email)
    email = PostEmailsMailer.with(post_email: post_email).post_email
    text = email.text_part.body.decoded

    assert_includes text, "Read online:"
    assert_includes text, "Unsubscribe:"
  end

  test "html email applies premailer transformations" do
    post_email = post_emails(:reader_one_email)

    delivered_email = PostEmailsMailer.with(post_email: post_email).post_email
    delivered_email.deliver_now

    html = ActionMailer::Base.deliveries.last.html_part.body.decoded

    assert_match(/class="post-title"[^>]*style="[^"]+"/i, html)
    assert_no_match(/<link[^>]+stylesheet/i, html)
  end

  test "html email keeps highlighted code block styles" do
    post_email = post_emails(:reader_one_email)
    post_email.post.update!(content: "```ruby\nputs 'hello'\n```")

    delivered_email = PostEmailsMailer.with(post_email: post_email).post_email
    delivered_email.deliver_now

    html = ActionMailer::Base.deliveries.last.html_part.body.decoded

    assert_match(/class="highlight"/i, html)
    assert_match(/hello/, html)
    assert_no_match(/```/, html)
  end
end
