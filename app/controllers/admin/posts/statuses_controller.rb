class Admin::Posts::StatusesController < Admin::ApplicationController
  before_action :set_post

  def publish
    apply_status_change(:publish)
  end

  def unpublish
    apply_status_change(:unpublish)
  end

  private
    def set_post
      @post = Post.find_by!(slug: params.expect(:slug))
    end

    def apply_status_change(command)
      if @post.public_send(command)
        flash_success status_change_message(command)
        redirect_to admin_post_path(@post)
      else
        flash_alert @post.errors.full_messages.to_sentence, now: true
        render "admin/posts/edit", status: :unprocessable_entity
      end
    end

    def status_change_message(command)
      if @post.saved_change_to_status?
        message = "Post was successfully #{status_change_verb(command)}."
        message << " Post emails were successfully stopped." if @post.pending_emails_were_stopped?
        message
      else
        "Post status was unchanged."
      end
    end

    def status_change_verb(command)
      "#{command}ed"
    end
end
