class Blog::Feed::Entry
  attr_reader :post, :feed

  delegate :id, :title, :author, :created_at, to: :post
  delegate :tag_uri, to: :feed

  def initialize(post:, feed:)
    @post = post
    @feed = feed
  end

  def populate(item)
    item.id = item_id
    item.title = title
    item.author = author_name
    item.link = post_url
    item.updated = updated_at.utc
    item.content.content = content
    item.content.type = "html"
  
    item
  end

  private
    def item_id
      tag_uri(created_date: created_at.to_date, identifier: identifier)
    end

    def identifier
      "Post/#{id}"
    end    

    def author_name
      author.full_name
    end

    def updated_at
      post.updated_at || default_updated_at
    end

    def default_updated_at
      Time.current
    end

    def content
      post.content.body.to_html
    end

    def post_url
      Rails.application.routes.url_helpers.post_url(post)
    end    
end
