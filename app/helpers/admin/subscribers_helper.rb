module Admin::SubscribersHelper
  def admin_subscriber_form_submit_text
    @subscriber.persisted? ? "update subscriber" : "create subscriber"
  end

  def admin_subscriber_form_cancel_path
    @subscriber.persisted? ? admin_subscriber_path(@subscriber) : admin_subscribers_path
  end

  def admin_subscriber_status_text(subscriber)
    subscriber.status.humanize
  end

  def admin_subscriber_updated_at_text(subscriber)
    standard_formatted_date(subscriber.updated_at)
  end

  def admin_subscribers_status_options
    Subscription::STATUSES.map { |status| [ status.humanize, status ] }
  end

  def admin_subscribers_searching_or_filtering?
    admin_subscribers_searching? || admin_subscribers_filtering?
  end

  def admin_subscribers_selected_status
    params[:status].presence
  end

  def admin_num_matching_subscribers_text
    pluralize(@page.unpaginated_record_count, "matching subscriber")
  end

  private
    def admin_subscribers_searching?
      search_term.present?
    end

    def admin_subscribers_filtering?
      admin_subscribers_selected_status.present?
    end
end
