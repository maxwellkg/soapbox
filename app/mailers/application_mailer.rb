class ApplicationMailer < ActionMailer::Base
  default from: "updates@example.com"
  layout "mailer"

  helper ApplicationHelper

  before_action :set_blog

  private
    def set_blog
      @blog = Blog.instance!
    end
end
