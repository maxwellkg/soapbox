class Admin::PostsController < Admin::ApplicationController
  before_action :set_post, only: %i[ show edit update destroy ]

  def index
    @posts = Post.with_rich_text_summary.order(updated_at: :desc)
  end

  def show
  end

  def new
    @post = Post.new
  end

  def create
    @post = Post.new(post_params)

    if @post.save
      flash_success "Post was successfully created."
      redirect_to admin_post_path(@post)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @post.update(post_params)
      flash_success "Post was successfully updated."
      redirect_to admin_post_path(@post)
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @post.destroy!
    flash_success "Post was successfully deleted."
    redirect_to admin_posts_path, status: :see_other
  end

  private
    def set_post
      @post = Post.find_by!(slug: params.expect(:slug))
    end

    def post_params
      params.expect(post: [ :title, :slug, :summary, :content, :pinned ])
    end
end
