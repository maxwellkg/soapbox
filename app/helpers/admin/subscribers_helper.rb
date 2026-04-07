module Admin::SubscribersHelper
  def admin_subscriber_form_submit_text
    @subscriber.persisted? ? "update subscriber" : "create subscriber"
  end

  def admin_subscriber_form_cancel_path
    @subscriber.persisted? ? admin_subscriber_path(@subscriber) : admin_subscribers_path
  end

  def admin_subscriber_status_text(subscriber)
    subscriber.active? ? "Active" : "Inactive"
  end

  def admin_subscriber_updated_at_text(subscriber)
    standard_formatted_date(subscriber.updated_at)
  end

  def admin_subscribers_selected_status
    params[:status].presence
  end

  def admin_subscribers_filtering?
    admin_subscribers_selected_status.present?
  end

  def admin_subscribers_searching?
    search_term.present? || admin_subscribers_filtering?
  end

  def admin_num_matching_subscribers_text
    pluralize(@subscribers.count, "matching subscriber")
  end
end
