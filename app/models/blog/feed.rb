require "rss"

class Blog::Feed
  attr_reader :blog

  delegate :title, :author, :created_at, to: :blog

  def initialize(blog)
    @blog = blog
  end

  def as_xml
    atom.to_xml
  end

  def atom
    build_atom_feed
  end

  def tag_uri(created_date:, identifier:)
    uri = URI(site_url)
    site = uri.host

    if uri.port.present? && uri.port != uri.class::DEFAULT_PORT
      site += ":#{uri.port}"
    end

    "tag:#{site},#{created_date}:#{identifier}"
  end

  private
    IDENTIFIER = "/feed"

    def build_atom_feed
      RSS::Maker.make("atom") do |maker|
        build_channel(maker.channel)
        build_items(maker.items)
      end
    end

    def build_channel(channel)
      channel.id = feed_id
      channel.title = title
      channel.author = author.full_name
      channel.updated = updated_at.utc

      build_channel_links(channel)
    end

    def build_channel_links(channel)
      build_self_link(channel)
      build_alternate_link(channel)
    end

    def build_self_link(channel)
      build_channel_link(channel, atom_feed_url, "self")
    end

    def build_alternate_link(channel)
      build_channel_link(channel, site_url, "alternate")
    end

    def build_channel_link(channel, href, rel)
      channel.links.new_link do |link|
        link.href = href
        link.rel = rel
      end
    end

    def build_items(items)
      posts.each do |post|
        add_post_to_items(post, items)
      end
    end

    def add_post_to_items(post, items)
      entry = build_entry(post)

      items.new_item { |item| entry.populate(item) }
    end

    def build_entry(post)
      Blog::Feed::Entry.new(post: post, feed: self)
    end

    def posts
      Post.published.with_markdown_content.order(published_at: :desc)
    end

    def updated_at
      posts.maximum(:updated_at) || default_feed_updated_at
    end

    def default_feed_updated_at
      Time.current
    end

    def feed_id
      tag_uri(created_date: created_date, identifier: IDENTIFIER)
    end

    def created_date
      created_at.to_date
    end

    def atom_feed_url
      Rails.application.routes.url_helpers.feed_url(format: :atom)
    end

    def site_url
      Rails.application.routes.url_helpers.root_url
    end
end
