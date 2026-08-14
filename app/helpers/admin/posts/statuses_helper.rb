module Admin::Posts::StatusesHelper
  def admin_post_status_change_button
    @post.draft? ? admin_post_publish_button : admin_post_unpublish_button
  end

  private
    def admin_post_publish_button
      button_to "Publish",
                publish_admin_post_path(@post),
                method: :patch,
                class: "btn btn-publish",
                form_class: "admin-action-form"
    end

    def admin_post_unpublish_button
      button_to "Unpublish",
                unpublish_admin_post_path(@post),
                method: :patch,
                class: "btn btn-unpublish",
                form_class: "admin-action-form"
    end
end
