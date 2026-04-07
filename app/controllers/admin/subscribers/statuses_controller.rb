class Admin::Subscribers::StatusesController < Admin::ApplicationController
  before_action :set_subscriber

  def activate
    apply_status_change(:activate)
  end

  def deactivate
    apply_status_change(:deactivate)
  end

  private
    DEFAULT_ERROR_MESSAGE = "Sorry, something went wrong."

    def set_subscriber
      @subscriber = Subscriber.find(params.expect(:id))
    end

    def apply_status_change(command)
      if @subscriber.public_send(command)
        flash_success "Subscriber was successfully #{command}d."
        redirect_to admin_subscriber_path(@subscriber)
      else
        flash_alert(status_change_error_message, now: true)
        render "admin/subscribers/edit", status: :unprocessable_entity
      end
    end

    def status_change_error_message
      status_change_error_messages.to_sentence.presence || DEFAULT_ERROR_MESSAGE
    end

    def status_change_error_messages
      status_change_errors.map(&:full_messages)
    end

    def status_change_errors
      [ @subscriber.errors, @subscriber.active_subscription&.errors ].compact_blank.flatten
    end
end
