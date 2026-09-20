class Admin::Posts::StatusesController < Admin::ApplicationController
  before_action :set_post

  def publish
    if @post.publish
      flash_success post_status_notice
      redirect_to admin_post_path(@post)
    else
      render_status_change_failure
    end
  end

  def unpublish
    if @post.unpublish
      flash_success post_status_notice
      redirect_to admin_post_path(@post)
    else
      render_status_change_failure
    end
  end

  private
    def set_post
      @post = Post.find_by!(slug: params.expect(:slug))
    end

    def post_status_notice
      if @post.published?
        "Post is published."
      elsif @post.draft?
        "Post is a draft."
      end
    end

    def render_status_change_failure
      flash_alert @post.errors.full_messages.to_sentence, now: true
      render "admin/posts/edit", status: :unprocessable_entity
    end
end
