class ApplicationMailer < ActionMailer::Base
  default from: "updates@example.com"
  layout "mailer"

  private
    def unsubscribe_headers(subscriber)
      {
        list_unsubscribe: "<#{subscriber_unsubscribe_url(subscriber)}>",
        list_unsubscribe_post: "List-Unsubscribe=One-Click"
      }
    end
end
