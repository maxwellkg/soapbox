require "test_helper"
require "rss"

class Blog::Feed::EntryTest < ActiveSupport::TestCase
  include Rails.application.routes.url_helpers

  test "populate maps post fields into atom entry" do
    post = posts(:published)
    item = build_item_for(post)

    assert_equal "tag:www.example.com,#{post.created_at.to_date}:Post/#{post.id}", item.id.content
    assert_equal post.title, item.title.content
    assert_equal post.updated_at.utc, item.updated.content
    assert_equal post.content.body.to_html, item.content.content
    assert_equal "html", item.content.type
    assert_equal Author.instance.full_name, item.author.name.content
  end

  test "populate maps post url using route helper" do
    post = posts(:published)
    item = build_item_for(post)

    assert_equal post_url(post), item.link.href
  end

  test "populate raises when singleton author is missing" do
    post = posts(:published)
    Author.delete_all

    assert_raises(ActiveRecord::RecordNotFound) { build_item_for(post) }
  end

  test "populate updated falls back to current time when post updated_at is nil" do
    post = posts(:published).dup
    post.id = posts(:published).id
    post.created_at = posts(:published).created_at
    post.define_singleton_method(:updated_at) { nil }

    freeze_time do
      item = build_item_for(post)

      assert_equal Time.current.utc, item.updated.content
    end
  end

  private
    def build_item_for(post)
      feed = Blog::Feed.new(Blog.instance)

      atom_feed = RSS::Maker.make("atom") do |maker|
                    maker.channel.id = "test"
                    maker.channel.title = "test"
                    maker.channel.author = "Test Author"
                    maker.channel.updated = Time.current.utc

                    maker.items.new_item do |item|
                      Blog::Feed::Entry.new(post: post, feed: feed).populate(item)
                    end
                  end

      atom_feed.items.first
    end
end
