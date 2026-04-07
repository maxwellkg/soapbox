module Admin::ApplicationHelper
  def back_to_admin_link
    link_to "back to admin", admin_root_path, class: "btn"
  end
end
