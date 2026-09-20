class Admin::Posts::EmailStatusesController < Admin::ApplicationController
  before_action :set_post

  def start
    if @post.start_emails
      flash_success email_status_notice
      redirect_to admin_post_path(@post)
    else
      render_email_status_change_failure
    end
  end

  def stop
    if @post.stop_emails
      flash_success email_status_notice
      redirect_to admin_post_path(@post)
    else
      render_email_status_change_failure
    end
  end

  private
    def set_post
      @post = Post.find_by!(slug: params.expect(:slug))
    end

    def email_status_notice
      if @post.email_status_pending?
        "Post emails are pending and can still be stopped."
      elsif @post.email_status_initiated?
        "Post emails have been initiated."
      elsif @post.email_status_not_started?
        "Post emails have not been started."
      end
    end

    def render_email_status_change_failure
      flash_alert @post.errors.full_messages.to_sentence, now: true
      render "admin/posts/edit", status: :unprocessable_entity
    end
end
