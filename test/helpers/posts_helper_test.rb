require "test_helper"

class PostsHelperTest < ActionView::TestCase
  test "highlights pre blocks using first line language" do
    html = highlight_code_blocks_rich_text_transform("<pre>ruby\nputs 'hello'</pre>")
    pre = Nokogiri::HTML.fragment(html).at_css("pre")

    assert_includes pre["class"], "highlight"
    assert_equal "puts 'hello'", pre.text.strip
    assert_includes pre.inner_html, "span"
  end

  test "leaves pre block unchanged when first line language is unknown" do
    html = highlight_code_blocks_rich_text_transform("<pre>madeuplang\nputs 'hello'</pre>")
    pre = Nokogiri::HTML.fragment(html).at_css("pre")

    assert_not_includes pre["class"].to_s, "highlight"
    assert_equal "madeuplang\nputs 'hello'", pre.text
  end

  test "leaves pre block unchanged without language first line" do
    html = highlight_code_blocks_rich_text_transform("<pre>puts 'hello'</pre>")
    pre = Nokogiri::HTML.fragment(html).at_css("pre")

    assert_not_includes pre["class"].to_s, "highlight"
    assert_equal "puts 'hello'", pre.text
  end

  test "leaves non pre rich text unchanged" do
    html = highlight_code_blocks_rich_text_transform("<p>Hello world</p>")

    assert_equal "<p>Hello world</p>", html
  end
end
