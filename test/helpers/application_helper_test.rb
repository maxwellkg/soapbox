require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "rouge highlight theme style tag renders highlight scope" do
    html = rouge_highlight_theme_style_tag
    style = Nokogiri::HTML.fragment(html).at_css("style")

    assert style.present?
    assert_includes style.text, ".highlight"
    assert_includes style.text, "background-color"
  end
end
