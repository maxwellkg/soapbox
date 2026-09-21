require "test_helper"

class PasswordsMailerTest < ActionMailer::TestCase
  test "reset sends to the author with reset subject" do
    email = PasswordsMailer.reset(authors(:instance))

    assert_equal [ authors(:instance).email_address ], email.to
    assert_equal "Reset your password", email.subject
  end

  test "reset renders html and text parts" do
    email = PasswordsMailer.reset(authors(:instance))

    assert_equal "multipart/alternative", email.mime_type
    assert_equal 2, email.parts.size
  end

  test "reset includes the blog identity in html and text parts" do
    email = PasswordsMailer.reset(authors(:instance))
    blog = Blog.instance!

    assert_includes email.html_part.body.decoded, blog.title
    assert_includes email.html_part.body.decoded, blog.subtitle
    assert_includes email.text_part.body.decoded, blog.title
    assert_includes email.text_part.body.decoded, blog.subtitle
  end

  test "reset includes the reset URL in html and text parts" do
    email = PasswordsMailer.reset(authors(:instance))

    assert_match %r{/passwords/.+/edit}, email.html_part.body.decoded
    assert_match %r{/passwords/.+/edit}, email.text_part.body.decoded
  end

  test "reset includes the expiration message in html and text parts" do
    email = PasswordsMailer.reset(authors(:instance))
    expires_in = ActionController::Base.helpers.distance_of_time_in_words(0, authors(:instance).password_reset_token_expires_in)

    assert_includes email.html_part.body.decoded, expires_in
    assert_includes email.text_part.body.decoded, expires_in
  end

  test "html email applies premailer transformations" do
    delivered_email = PasswordsMailer.reset(authors(:instance))
    delivered_email.deliver_now

    html = ActionMailer::Base.deliveries.last.html_part.body.decoded

    assert_match(/class="blog-header-title"[^>]*style="[^"]+"/i, html)
    assert_no_match(/<link[^>]+stylesheet/i, html)
  end
end
