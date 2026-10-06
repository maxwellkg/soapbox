require "test_helper"

class ActionTextMarkdownTest < ActiveSupport::TestCase
  test "to_html sanitizes rendered Markdown" do
    markdown = ActionText::Markdown.new(
      content: "# Heading\n\n<mark>Allowed</mark><script>alert('nope')</script>"
    )

    html = markdown.to_html
    fragment = Nokogiri::HTML.fragment(html)

    assert_predicate html, :html_safe?
    assert_equal "Heading #", fragment.at_css("h1").text.strip
    assert_equal "Allowed", fragment.at_css("mark").text
    assert_nil fragment.at_css("script")
  end
end
