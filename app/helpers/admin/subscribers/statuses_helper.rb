module Admin::Subscribers::StatusesHelper
  def admin_subscriber_status_change_button
    @subscriber.active? ? admin_subscriber_deactivate_button : admin_subscriber_activate_button
  end

  private
    def admin_subscriber_activate_button
      button_to "activate",
                activate_admin_subscriber_path(@subscriber),
                method: :patch,
                class: "btn btn-publish",
                form_class: "admin-action-form"
    end

    def admin_subscriber_deactivate_button
      button_to "deactivate",
                deactivate_admin_subscriber_path(@subscriber),
                method: :patch,
                class: "btn btn-unpublish",
                form_class: "admin-action-form"
    end
end
