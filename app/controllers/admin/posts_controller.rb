class Admin::PostsController < Admin::ApplicationController
  include Searchable::Controller
  include Pagination::Controller

  before_action :set_post, only: %i[ show edit update destroy ]

  def index
    @posts =  paginate(
                Post
                  .with_markdown_summary
                  .search_title_summary_and_content(search_term)
                  .where(filter_conditions)
                  .order(updated_at: :desc)
              )
  end

  def show
  end

  def new
    @post = Post.new
  end

  def create
    @post = Post.new(post_creation_params)

    if @post.save
      flash_success "Post was successfully created."
      redirect_to edit_admin_post_path(@post)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @post.update(post_update_params)
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

    def post_creation_params
      params.expect(post: [ :title, :slug ])
    end

    def post_update_params
      params.expect(post: [ :title, :slug, :summary, :content, :pinned ])
    end

    def filter_conditions
      { status: filter_params[:status] }.compact_blank
    end

    def filter_params
      params.permit(:status)
    end
end
