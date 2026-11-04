module ThemeHelper
  def theme_stylesheet
    "themes/#{current_theme}"
  end

  private
    def current_theme
      @blog&.theme || Blog::DEFAULT_THEME
    end
end
