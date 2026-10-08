class ApplicationMailer < ActionMailer::Base
  before_action :set_blog

  default from: -> { email_address_with_name(notifications_address, blog_title) }
  layout "mailer"

  private
    def set_blog
      @blog = Blog.instance!
    end

    def blog_title
      @blog.title
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
