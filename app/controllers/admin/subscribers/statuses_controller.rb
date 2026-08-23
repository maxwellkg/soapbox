class Admin::Subscribers::StatusesController < Admin::ApplicationController
  before_action :set_subscriber

  def subscribe
    apply_status_change(:subscribe)
  end

  def unsubscribe
    apply_status_change(:unsubscribe)
  end

  private
    DEFAULT_ERROR_MESSAGE = "Sorry, something went wrong."

    SUCCESS_MESSAGES = {
      subscribe: "Subscriber was successfully updated. Confirmation is pending.",
      unsubscribe: "Subscriber was successfully unsubscribed."
    }

    def set_subscriber
      @subscriber = Subscriber.find(params.expect(:id))
    end

    def apply_status_change(command)
      if apply_status_change_command(command)
        flash_success success_message_for(command)
        redirect_to admin_subscriber_path(@subscriber)
      else
        flash_alert status_change_error_message
        redirect_to admin_subscriber_path(@subscriber)
      end
    end

    def status_change_error_message
      status_change_error_messages.to_sentence.presence || DEFAULT_ERROR_MESSAGE
    end

    def status_change_error_messages
      status_change_errors.map(&:full_messages)
    end

    def status_change_errors
      [ @subscriber.errors, @subscriber.latest_subscription&.errors ].compact_blank.flatten
    end

    def apply_status_change_command(command)
      @subscriber.public_send(command)
    end

    def success_message_for(command)
      SUCCESS_MESSAGES[command]
    end
end
