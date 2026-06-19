module ApplicationHelper
  DEFAULT_ICON = "/icon.png"

  def rouge_highlight_theme_style_tag
    tag.style do
      Rouge::Themes::Gruvbox.mode(:light).render(scope: ".highlight")
    end
  end

  def site_icon_url
    blog_has_icon? ? url_for_blog_icon_from_site_image : DEFAULT_ICON
  end

  def standard_formatted_date(date)
    date.strftime("%d %B %Y")
  end

  private
    def blog_has_icon?
      Blog.instance? && Blog.instance.site_image.attached?
    end

    def url_for_blog_icon_from_site_image
      url_for(Blog.instance.site_image.variant(resize_to_fill: [ 512, 512 ]))
    end
end
