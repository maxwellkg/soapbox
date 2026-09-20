class Admin::AuthorsController < Admin::ApplicationController
  before_action :set_author

  def show
  end

  def edit
  end

  def update
    if @author.update(author_params)
      flash_success "Account was successfully updated"
      redirect_to admin_author_path
    else
      flash_error "Something went wrong", now: true
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def set_author
      @author = Author.instance!
    end

    def author_params
      params.expect(author: [ :first_name, :last_name, :email_address ])
    end
end
