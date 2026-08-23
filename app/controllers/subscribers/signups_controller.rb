class Subscribers::SignupsController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 3, within: 10.minutes, only: :create, with: :handle_rate_limited_signup

  def create
    if honeypot_filled?
      handle_honeypot_signup
      return
    end

    @signup = Subscriber.find_or_initialize_by(signup_params)

    if @signup.active?
      flash_success "Thanks for subscribing.", now: true
      set_signup
    elsif subscribe_signup
      flash_success "Check your inbox to confirm your subscription.", now: true
      set_signup
    else
      flash_alert "Sorry, something went wrong", now: true
      render :create, status: :unprocessable_entity
    end
  end

  private
    def subscribe_signup
      @signup.persisted? ? @signup.subscribe : @signup.save
    end

    def signup_params
      params.expect(subscriber: [ :email_address ])
    end

    def honeypot_filled?
      params.dig(:subscriber, :name).present?
    end

    def handle_honeypot_signup
      set_signup
      flash_success "Thanks for subscribing.", now: true
      render :create
    end

    def handle_rate_limited_signup
      set_signup
      flash_alert "Too many signup attempts. Try again in 10 minutes.", now: true
      render :create, status: :too_many_requests
    end

    def set_signup
      @signup = Subscriber.new
    end
end
