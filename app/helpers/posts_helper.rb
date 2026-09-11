module PostsHelper
  def post_title_tag(for_email: false)
    tag_type = for_email ? :h2 : :h1

    content_tag tag_type, class: "post-title" do
      link_to @post.title, @post, class: "post-title-link"
    end
  end

  def post_preview_content(post)
    post.summary? ? post_summary_preview(post) : post_excerpt_preview(post)
  end

  def post_summary_preview(post)
    sanitize_content(post.summary.to_html)
  end

  def post_excerpt_preview(post)
    tag.p(post.excerpt)
  end

  def no_matching_posts_text
    search_term.present? ? "No matching posts" : "No posts yet"
  end
end
