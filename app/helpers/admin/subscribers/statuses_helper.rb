module Admin::Subscribers::StatusesHelper
  def admin_subscriber_status_change_button
    @subscriber.active? ? admin_subscriber_unsubscribe_button : admin_subscriber_subscribe_button
  end

  private
    def admin_subscriber_subscribe_button
      button_to "subscribe",
                subscribe_admin_subscriber_path(@subscriber),
                method: :patch,
                class: "btn btn-publish",
                form_class: "admin-action-form"
    end

    def admin_subscriber_unsubscribe_button
      button_to "unsubscribe",
                unsubscribe_admin_subscriber_path(@subscriber),
                method: :patch,
                class: "btn btn-unpublish",
                form_class: "admin-action-form"
    end
end
