module Admin::Posts::StatusesHelper
  def admin_post_status_change_button
    @post.draft? ? admin_post_publish_button : admin_post_unpublish_button
  end

  private
    def admin_post_publish_button
      button_to "publish",
                publish_admin_post_path(@post),
                method: :patch,
                class: "btn btn-primary",
                form_class: "admin-post-action-form"
    end

    def admin_post_unpublish_button
      button_to "unpublish",
                unpublish_admin_post_path(@post),
                method: :patch,
                class: "btn",
                form_class: "admin-post-action-form"
    end
end
