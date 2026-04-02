class Subscribers::UnsubscribesController < ApplicationController
  allow_unauthenticated_access

  before_action :set_subscriber

  def unsubscribe
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
