class Admin::Posts::EmailStatusesController < Admin::ApplicationController
  before_action :set_post

  def start
    apply_email_status_change(:start)
  end

  def stop
    apply_email_status_change(:stop)
  end

  private
    def set_post
      @post = Post.find_by!(slug: params.expect(:slug))
    end

    def apply_email_status_change(action)
      if @post.public_send(email_status_command_for(action))
        flash_success email_status_change_message(action)
        redirect_to admin_post_path(@post)
      else
        flash_alert @post.errors.full_messages.to_sentence, now: true
        render "admin/posts/edit", status: :unprocessable_entity
      end
    end

    def email_status_change_message(action)
      if @post.saved_change_to_email_status?
        "Post emails were successfully #{email_status_change_verb(action)}."
      else
        "Post email status was unchanged."
      end
    end

    def email_status_change_verb(action)
      case action
      when :start
        "started"
      when :stop
        "stopped"
      end
    end

    def email_status_command_for(action)
      "#{action}_emails!".to_sym
    end
end
