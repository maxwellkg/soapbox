module ApplicationHelper
  def rouge_highlight_theme_style_tag
    tag.style do
      Rouge::Themes::Gruvbox.mode(:light).render(scope: ".highlight")
    end
  end

  def standard_formatted_date(date)
    date.strftime("%d %B %Y")
  end
end
