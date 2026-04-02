class PostsController < ApplicationController
  include Searchable::Controller

  allow_unauthenticated_access

  def index
    @blog = Blog.instance!
    @signup = Subscriber.new

    respond_to do |format|
      format.atom { render xml: @blog.as_atom_feed_xml }
      format.html { set_posts }
    end
  end

  def show
    @blog = Blog.instance!
    @signup = Subscriber.new
    @post = Post.published.with_rich_text_content.find_by!(slug: params.expect(:slug))
  end

  private
    def set_posts
      @posts = Post
                .search_title_summary_and_content(search_term)
                .with_rich_text_summary
                .with_rich_text_content
                .ordered_for_display
    end
end
