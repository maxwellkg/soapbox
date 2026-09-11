require "test_helper"

class PostsHelperTest < ActionView::TestCase
  include ApplicationHelper

  test "post_preview_content renders author summary without an added wrapper" do
    post = posts(:published)
    post.summary = "Custom summary"
    html = post_preview_content(post).to_s

    assert_includes html, "Custom summary"
    assert_equal sanitize_content(post.summary.to_html).to_s, html
  end

  test "post_preview_content wraps derived excerpt in a paragraph when no summary" do
    post = posts(:draft)
    post.content = "Hello world from Soapbox"
    html = post_preview_content(post)

    assert_equal tag.p(post.excerpt).to_s, html.to_s
    assert_equal "Hello world from Soapbox", Nokogiri::HTML.fragment(html).at_css("p").text
  end

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
