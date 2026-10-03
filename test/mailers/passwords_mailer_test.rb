require "test_helper"

class PasswordsMailerTest < ActionMailer::TestCase
  test "email uses the blog identity and admin address" do
    email = PasswordsMailer.reset(authors(:instance))

    assert_equal [ "admin@#{ActionMailer::Base.default_url_options.fetch(:host)}" ], email.from
    assert_equal [ Blog.instance!.title ], email[:from].display_names
    assert_nil email.reply_to
  end
end
