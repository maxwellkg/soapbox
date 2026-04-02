class Subscribers::SignupsController < ApplicationController
  allow_unauthenticated_access

  def create
    @signup = Subscriber.find_or_initialize_by(signup_params)

    if @signup.activate
      flash_success "#{@signup.email_address} is now subscribed!", now: true

      @signup = Subscriber.new
    else
      flash_alert "Sorry, something went wrong", now: true
      render :create, status: :unprocessable_entity
    end
  end

  private
    def signup_params
      params.expect(subscriber: [ :email_address ])
    end
end
