require "test_helper"

class ThemeCSSLoaderTest < ActiveSupport::TestCase
  test "resolves theme stylesheets to literal values" do
    url = ApplicationController.helpers.stylesheet_path("themes/editorial")

    css = ThemeCSSLoader.load(url)

    assert_not_nil css
    assert_includes css, "#f6f0e4"
    assert_no_match(/var\(/, css)
  end

  test "resolves base email stylesheets against the active theme palette" do
    url = ApplicationController.helpers.stylesheet_path("mailer")

    Blog.instance.update!(theme: "editorial")
    css = ThemeCSSLoader.load(url)
    assert_includes css, "#f6f0e4"

    Blog.instance.update!(theme: "terminal")
    css = ThemeCSSLoader.load(url)
    assert_includes css, "#0e1923"
  end

  test "leaves assets Propshaft cannot find to the standard strategies" do
    assert_nil ThemeCSSLoader.load("/assets/does-not-exist-0123456789ab.css")
  end

  test "raises when a stylesheet references an undefined variable" do
    error = assert_raises(RuntimeError) do
      Blog.instance.update!(theme: "terminal")
      ThemeCSSLoader.resolve("a { color: var(--nope); }")
    end

    assert_match(/--nope/, error.message)
  end
end
