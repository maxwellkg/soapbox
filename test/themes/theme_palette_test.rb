require "test_helper"

class ThemePaletteTest < ActiveSupport::TestCase
  THEMES = Blog.themes.keys
  STYLESHEETS = Dir[Rails.root.join("app/assets/stylesheets/**/*.css")].map { |path| Pathname.new(path) }

  def palette(theme)
    File.read(Rails.root.join("app/assets/stylesheets/themes/#{theme}.css"))
      .scan(/--([\w-]+):\s*([^;]+);/)
      .to_h { |name, value| [ name, value.strip ] }
  end

  def referenced_variables
    STYLESHEETS.flat_map { |sheet| File.read(sheet).scan(/var\(\s*--([\w-]+)/) }.flatten.uniq
  end

  test "every theme defines the same palette keys" do
    key_sets = THEMES.map { |theme| palette(theme).keys.sort }

    assert_equal [ key_sets.first ], key_sets.uniq, "theme palettes define different variable sets"
  end

  test "every referenced variable is defined by every theme" do
    missing = THEMES.flat_map do |theme|
      referenced_variables.reject { |name| palette(theme).key?(name) }
    end

    assert_empty missing, "stylesheets reference variables no theme palette defines"
  end

  test "palette values are literal" do
    offenders = THEMES.flat_map do |theme|
      palette(theme).filter_map { |name, value| name if value.include?("var(") }
    end

    assert_empty offenders, "theme palettes must hold literal values for email resolution"
  end

  test "every palette variable is referenced by a stylesheet" do
    unreferenced = THEMES.flat_map do |theme|
      palette(theme).keys.reject { |name| referenced_variables.include?(name) }
    end

    assert_empty unreferenced, "theme palettes hold variables no stylesheet consumes"
  end
end
