class Subscribers::UnsubscribesController < ApplicationController
  allow_unauthenticated_access

  before_action :set_subscriber

  def unsubscribe
    if @subscriber.unsubscribe
      redirect_to root_path, notice: "#{@subscriber.email_address} has been unsubscribed"
    else
      redirect_to root_path, alert: "Sorry, something went wrong. Please try again."
    end
  end

  private

    def set_subscriber
      @subscriber = Subscriber.find_by_unsubscribe_token!(params.expect(:token))
    rescue ActiveRecord::RecordNotFound, ActiveSupport::MessageVerifier::InvalidSignature
      redirect_to root_path, alert: "Unsubscribe link is invalid or has expired."
    end
end
