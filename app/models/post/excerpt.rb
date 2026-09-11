class Post::Excerpt
  WORD_LIMIT = 80

  def initialize(post)
    @words = post.plain_text_content.to_s.split
  end

  def text
    return nil if words.empty?

    truncated? ? "#{opening}..." : opening
  end

  private
    attr_reader :words

    def opening
      words.first(WORD_LIMIT).join(" ")
    end

    def truncated?
      words.count > WORD_LIMIT
    end
end
