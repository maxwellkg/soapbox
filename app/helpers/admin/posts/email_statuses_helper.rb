module Admin::Posts::EmailStatusesHelper
  def admin_post_email_status_change_button
    if @post.can_start_emails?
      admin_post_start_emails_button
    elsif @post.can_stop_emails?
      admin_post_stop_emails_button
    end
  end

  private
    def admin_post_start_emails_button
      button_to "start emails",
                start_emails_admin_post_path(@post),
                method: :patch,
                class: "btn btn-publish",
                form_class: "admin-action-form"
    end

    def admin_post_stop_emails_button
      button_to "stop emails",
                stop_emails_admin_post_path(@post),
                method: :patch,
                class: "btn btn-unpublish",
                form_class: "admin-action-form"
    end
end
