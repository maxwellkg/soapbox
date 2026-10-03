class ApplicationMailer < ActionMailer::Base
  default from: -> { email_address_with_name(notifications_address, blog_title) }
  layout "mailer"

  private
    def blog_title
      Blog.instance!.title
    end

    def notifications_address
      blog_email_address("notifications")
    end

    def blog_email_address(local_part)
      "#{local_part}@#{blog_domain}"
    end

    def blog_domain
      default_url_options.fetch(:host)
    end

    def unsubscribe_headers(subscriber)
      {
        list_unsubscribe: "<#{subscriber_unsubscribe_url(subscriber)}>",
        list_unsubscribe_post: "List-Unsubscribe=One-Click"
      }
    end
end
