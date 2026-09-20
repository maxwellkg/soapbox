module PostsHelper
  def post_title_tag
    content_tag :h1, class: "post-title" do
      link_to @post.title, @post, class: "post-title-link"
    end
  end

  def post_preview_content(post)
    post.summary? ? post_summary_preview(post) : post_excerpt_preview(post)
  end

  def no_matching_posts_text
    search_term.present? ? "No matching posts" : "No posts yet"
  end

  private
    def post_summary_preview(post)
      sanitize_content(post.summary.to_html)
    end

    def post_excerpt_preview(post)
      tag.p(post.excerpt)
    end
end
