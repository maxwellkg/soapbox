module Admin::PostsHelper
  def admin_post_form_submit_text
    @post.persisted? ? "Update post" : "Create post"
  end

  def admin_post_form_cancel_path
    @post.persisted? ? admin_post_path(@post) : admin_posts_path
  end

  def admin_post_status_text(post)
    post.published? ? "Published" : "Draft"
  end

  def admin_post_email_status_text(post)
    post.email_status.humanize
  end

  def admin_post_updated_at_text(post)
    standard_formatted_date(post.updated_at)
  end

  def admin_post_published_at_text(post)
    post.published? ? standard_formatted_date(post.published_at) : "Not published"
  end

  def admin_post_status_note_style_class
    @post.draft? ? "admin-status-note-draft" : "admin-status-note-published"
  end

  def admin_post_delete_button
    button_to "Delete",
              admin_post_path(@post),
              method: :delete,
              class: "btn btn-error",
              form_class: "admin-action-form",
              data: { turbo_confirm: "delete this post?" }
  end

  def admin_posts_selected_status
    params[:status].presence
  end

  def admin_posts_searching?
    search_term.present? || admin_posts_selected_status.present?
  end

  def admin_num_matching_posts_text
    pluralize(@page.unpaginated_record_count, "matching post")
  end
end
