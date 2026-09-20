class ApplicationMailer < ActionMailer::Base
  default from: "updates@example.com"
  layout "mailer"

  before_action :set_blog

  private
    def set_blog
      @blog = Blog.instance!
    end
end
