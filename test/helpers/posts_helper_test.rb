require "test_helper"

class PostsHelperTest < ActionView::TestCase
  include ApplicationHelper

  test "post_preview_content sanitizes html and preserves highlighted code classes" do
    post = posts(:published)
    post.content = "## Section One\n\n```ruby\nputs 'hello'\n```\n\n<script>alert('nope')</script>"
    post.summary = post.content.content
    html = post_preview_content(post)
    fragment = Nokogiri::HTML.fragment(html)

    assert_nil fragment.at_css("script")
    assert_equal "#section-one", fragment.at_css("a.heading__link")["href"]
    assert_includes fragment.at_css("pre")["class"].to_s, "highlight"
    assert_includes fragment.to_html, "span"
  end
end
