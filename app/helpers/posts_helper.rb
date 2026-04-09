module PostsHelper
  def post_title_tag(for_email: false)
    tag_type = for_email ? :h2 : :h1

    content_tag tag_type, class: "post-title" do
      link_to @post.title, @post, class: "post-title-link"
    end
  end

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

  def highlighted_rich_text(rich_text)
    highlight_code_blocks_rich_text_transform(rich_text).html_safe
  end

  def highlight_code_blocks_rich_text_transform(rich_text)
    document = Nokogiri::HTML.fragment(rich_text.to_s)

    document.css("pre").each do |code_block|
      language, source = code_block.text.split(/\r?\n/, 2)
      language = language.to_s.strip.downcase

      next if language.blank? || source.blank?

      lexer = Rouge::Lexer.find(language)

      next unless lexer.present?

      formatter = Rouge::Formatters::HTML.new
      formatted = formatter.format(lexer.lex(source))

      code_block.children.remove
      code_block.add_child(formatted)

      code_block["class"] = [ code_block["class"], "highlight" ].select(&:present?).join(" ")
    end

    document.to_html
  end
end
