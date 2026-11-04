# Email clients cannot resolve CSS custom properties, and Premailer would inline
# var() references verbatim into delivered HTML. Themes are palettes of custom
# properties and the base stylesheets consume them with var(); this loader
# expands every email stylesheet against the active theme's palette before
# Premailer sees it, so delivered HTML contains only literal values. The web
# keeps the variables and needs no equivalent step.
module ThemeCSSLoader
  def self.load(url)
    css = Premailer::Rails::CSSLoaders::PropshaftLoader.load(url)
    css && resolve(css)
  end

  def self.resolve(css)
    palette = theme_palette.merge(definitions(css))

    css.gsub(/var\(\s*--([\w-]+)\s*\)/) do
      name = Regexp.last_match(1)
      palette.fetch(name) { raise "Theme is missing variable --#{name}" }
    end
  end

  def self.theme_palette
    theme = Blog.instance&.theme || Blog::DEFAULT_THEME
    path = "themes/#{theme}.css"
    definitions(Premailer::Rails::CSSLoaders::PropshaftLoader.load(path).to_s)
  end

  def self.definitions(css)
    css.scan(/--([\w-]+):\s*([^;]+);/).to_h { |name, value| [ name, value.strip ] }
  end
end
