module ApplicationHelper
  DEFAULT_ICON = "/icon.png"

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
      url_for(blog_image_resized_for_icon)
    end

    def blog_image_resized_for_icon
      Blog.instance.resized_site_image(512)
    end
end
