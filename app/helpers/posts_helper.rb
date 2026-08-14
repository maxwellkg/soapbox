module PostsHelper
  def post_title_tag(for_email: false)
    tag_type = for_email ? :h2 : :h1

    content_tag tag_type, class: "post-title" do
      link_to @post.title, @post, class: "post-title-link"
    end
  end

  def post_preview_content(post)
    post.summary? ? sanitize_content(post.summary.to_html) : post_preview_content_from_post_content(post)
  end

  def post_preview_content_from_post_content(post)
    tag.p(post_summary_from_content(post))
  end

  def post_summary_from_content(post)
    summary_words = ActionText::Content.new(post.content.to_html).to_plain_text.to_s.split
    summary_text = summary_words.first(80).join(" ")

    summary_words.count > 80 ? "#{summary_text}..." : summary_text
  end

  def no_matching_posts_text
    search_term.present? ? "No matching posts" : "No posts yet"
  end
end
