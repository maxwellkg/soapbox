class PasswordsController < ApplicationController
  allow_unauthenticated_access
  before_action :set_author_by_token, only: %i[ edit update ]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> { redirect_to new_password_path, alert: "Try again later." }

  def new
  end

  def create
    if author = Author.find_by(email_address: params[:email_address])
      PasswordsMailer.reset(author).deliver_later
    end

    flash_success "Password reset instructions sent (if author with that email address exists)."
    redirect_to new_session_path
  end

  def edit
  end

  def update
    if @author.update(params.permit(:password, :password_confirmation))
      @author.sessions.destroy_all
      flash_success "Password has been reset."
      redirect_to new_session_path
    else
      flash_alert "Passwords did not match."
      redirect_to edit_password_path(params[:token])
    end
  end

  private
    def set_author_by_token
      @author = Author.find_by_password_reset_token!(params[:token])
    rescue ActiveSupport::MessageVerifier::InvalidSignature
      flash_alert "Password reset link is invalid or has expired."
      redirect_to new_password_path
    end
end
