class PostsController < ApplicationController
  include Searchable::Controller
  include Pagination::Controller

  before_action :set_blog, :set_signup

  allow_unauthenticated_access

  def index
    respond_to do |format|
      format.atom { render xml: @blog.feed_xml }
      format.html { set_posts }
    end
  end

  def show
    @post = Post.published.with_markdown_content.find_by!(slug: params.expect(:slug))
  end

  private
    def set_blog
      @blog = Blog.instance!
    end

    def set_signup
      @signup = Subscriber.new
    end

    def set_posts
      @posts =  paginate(
                  Post
                    .search_title_summary_and_content(search_term)
                    .with_markdown_summary
                    .with_markdown_content
                    .ordered_for_display
                )
    end
end
