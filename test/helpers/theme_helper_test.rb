require "test_helper"

class ThemeHelperTest < ActionView::TestCase
  setup do
    @blog = blogs(:instance)
  end

  test "terminal theme helpers use the singleton blog" do
    assert_equal "themes/terminal", theme_stylesheet
  end

  test "editorial theme helpers use the singleton blog" do
    @blog.update!(theme: "editorial")

    assert_equal "themes/editorial", theme_stylesheet
  end

  test "theme helpers use terminal before the blog is set up" do
    Blog.delete_all
    @blog = nil

    assert_equal "themes/terminal", theme_stylesheet
  end
end
