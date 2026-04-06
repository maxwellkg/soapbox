module PostsHelper
  def post_preview_content(post)
    post.summary.presence || post_preview_content_from_post_content(post)
  end

  def post_preview_content_from_post_content(post)
    tag.p(post_summary_from_content(post))
  end

  def post_summary_from_content(post)
    summary_words = post.content.body.to_plain_text.to_s.split
    summary_text = summary_words.first(80).join(" ")

    summary_words.count > 80 ? "#{summary_text}..." : summary_text
  end

  def no_matching_posts_text
    search_term.present? ? "No matching posts" : "No posts yet"
  end
end
