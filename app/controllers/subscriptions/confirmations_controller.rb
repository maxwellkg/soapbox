class Subscriptions::ConfirmationsController < ApplicationController
  allow_unauthenticated_access

  before_action :set_subscription

  def show
  end

  def update
    if @subscription.confirm
      flash_success "#{@subscription.subscriber.email_address} is now subscribed!"
    else
      flash_alert "Sorry, something went wrong. Please try again."
    end

    redirect_to root_path
  end

  private
    def set_subscription
      @subscription = Subscription.find_by_confirmation_token!(params.expect(:token))
    rescue ActiveRecord::RecordNotFound, ActiveSupport::MessageVerifier::InvalidSignature
      flash_alert "Confirmation link is no longer valid."
      redirect_to root_path
    end
end
