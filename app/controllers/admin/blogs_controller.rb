class Admin::BlogsController < Admin::ApplicationController
  before_action :set_blog

  def show
  end

  def edit
  end

  def update
    if @blog.update(blog_params)
      flash_success "Blog was successfully updated"
      redirect_to admin_blog_path
    else
      flash_error "Something went wrong", now: true
      render :edit, status: :unprocessable_entity
    end
  end

  private
    def set_blog
      @blog = Blog.instance
    end

    def blog_params
      params.expect(blog: [ :title, :subtitle, :description, :site_image, :should_remove_site_image ])
    end
end
