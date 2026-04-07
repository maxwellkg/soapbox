require "test_helper"
require "rss"

class Blog::FeedTest < ActiveSupport::TestCase
  include Rails.application.routes.url_helpers

  test "atom_feed builds channel metadata" do
    blog = Blog.instance
    atom_feed = Blog::Feed.new(blog).atom_feed

    assert_equal blog.title, atom_feed.title.content
    assert_equal expected_feed_id(blog), atom_feed.id.content
    assert_equal Post.published.maximum(:updated_at).utc, atom_feed.updated.content
  end

  test "atom_feed has self and alternate links" do
    atom_feed = Blog::Feed.new(Blog.instance).atom_feed

    self_link = atom_feed.links.find { |link| link.rel == "self" }
    alternate_link = atom_feed.links.find { |link| link.rel == "alternate" }

    assert_equal feed_url(format: :atom), self_link.href
    assert_equal root_url, alternate_link.href
  end

  test "atom_feed includes published posts only in published_at descending order" do
    atom_feed = Blog::Feed.new(Blog.instance).atom_feed

    expected_posts = Post.published.with_rich_text_content.order(published_at: :desc).to_a

    expected_post_entry_ids = expected_posts.map do |post|
                                expected_entry_id(post)
                              end

    actual_post_entry_ids = atom_feed.items.map { |item| item.id.content }
    draft_entry_ids = Post.draft.map { |post| expected_entry_id(post) }

    assert_equal expected_posts.count, atom_feed.items.count
    assert_equal expected_post_entry_ids, actual_post_entry_ids
    assert draft_entry_ids.none? { |entry_id| entry_id.in?(actual_post_entry_ids) }
  end

  test "atom_feed raises when singleton author is missing" do
    Author.delete_all

    assert_raises(ActiveRecord::RecordNotFound) { Blog::Feed.new(Blog.instance).atom_feed }
  end

  test "atom_feed updated falls back to current time when no published posts exist" do
    Post.update_all(status: "draft", published_at: nil, email_status: "not_started", start_emails_job_key: nil)

    freeze_time do
      atom_feed = Blog::Feed.new(Blog.instance).atom_feed

      assert_equal Time.current.utc, atom_feed.updated.content
    end
  end

  test "tag_uri includes non-default port in host" do
    feed = Blog::Feed.new(Blog.instance)
    feed.define_singleton_method(:site_url) { "http://localhost:3000/" }

    assert_equal "tag:localhost:3000,2025-01-01:/feed", feed.tag_uri(created_date: Date.new(2025, 1, 1), identifier: "/feed")
  end

  test "tag_uri omits default port in host" do
    feed = Blog::Feed.new(Blog.instance)
    feed.define_singleton_method(:site_url) { "http://www.example.com:80/" }

    assert_equal "tag:www.example.com,2025-01-01:/feed", feed.tag_uri(created_date: Date.new(2025, 1, 1), identifier: "/feed")
  end

  private
    def expected_feed_id(blog)
      "tag:#{expected_site},#{blog.created_at.to_date}:/feed"
    end

    def expected_entry_id(post)
      "tag:#{expected_site},#{post.created_at.to_date}:Post/#{post.id}"
    end

    def expected_site
      uri = URI(root_url)
      return uri.host if uri.port.nil? || uri.port == uri.class::DEFAULT_PORT

      "#{uri.host}:#{uri.port}"
    end
end
