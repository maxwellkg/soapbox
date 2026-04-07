class Admin::SubscribersController < Admin::ApplicationController
  include Searchable::Controller

  before_action :set_subscriber, only: %i[ show edit update ]

  def index
    @subscribers =  Subscriber
                      .includes(:active_subscription)
                      .search_email_address(search_term)
                      .for_status(filter_params[:status])
                      .order(updated_at: :desc)
  end

  def show
  end

  def new
    @subscriber = Subscriber.new
  end

  def create
    @subscriber = Subscriber.new(subscriber_params)

    if @subscriber.activate
      flash_success "Subscriber was successfully created."
      redirect_to admin_subscriber_path(@subscriber)
    else
      flash_alert "Sorry, something went wrong.", now: true
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @subscriber.update(subscriber_params)
      flash_success "Subscriber was successfully updated."
      redirect_to admin_subscriber_path(@subscriber)
    else
      flash_alert "Sorry, something went wrong.", now: true
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def set_subscriber
      @subscriber = Subscriber.find(params.expect(:id))
    end

    def subscriber_params
      params.expect(subscriber: [ :email_address ])
    end

    def filter_params
      params.permit(:status)
    end
end
