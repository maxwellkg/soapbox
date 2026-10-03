require "test_helper"

class ApplicationMailerTest < ActionMailer::TestCase
  class NotificationsMailer < ApplicationMailer
    def notification
      mail(to: "reader@example.com", subject: "Notification", body: "Notification")
    end
  end

  test "default sender uses the blog identity and notifications address" do
    email = NotificationsMailer.notification

    assert_equal [ "notifications@#{ActionMailer::Base.default_url_options.fetch(:host)}" ], email.from
    assert_equal [ Blog.instance!.title ], email[:from].display_names
  end
end
