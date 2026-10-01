class Subscribers::UnsubscribesController < ApplicationController
  allow_unauthenticated_access
  # RFC 8058 one-click unsubscribe is POSTed by the mail client, without cookies or a CSRF token
  skip_forgery_protection only: :one_click

  before_action :set_subscriber, only: %i[ show complete ]

  def one_click
    subscriber = Subscriber.find_by_unsubscribe_token(params.expect(:token))

    if subscriber.nil?
      head :not_found
    elsif subscriber.unsubscribe
      head :ok
    else
      head :internal_server_error
    end
  end

  def show
  end

  def complete
    if @subscriber.unsubscribe
      flash_success "#{@subscriber.email_address} has been unsubscribed"
    else
      flash_alert "Sorry, something went wrong. Please try again."
    end

    redirect_to root_path
  end

  private

    def set_subscriber
      @subscriber = Subscriber.find_by_unsubscribe_token!(params.expect(:token))
    rescue ActiveRecord::RecordNotFound, ActiveSupport::MessageVerifier::InvalidSignature
      flash_alert "Unsubscribe link is invalid or has expired."
      redirect_to root_path
    end
end
