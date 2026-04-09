module Pagination::PaginationHelper
  def render_pagination_controls
    return unless show_pagination_controls?

    tag.nav class: "pagination", "aria-label": "Pagination" do
      safe_join([ pagination_previous_control, pagination_page_indicator, pagination_next_control ])
    end
  end

  private
    def show_pagination_controls?
      @page.present? && @page.total_pages > 1
    end

    def pagination_previous_control
      if @page.has_previous?
        link_to "Previous", pagination_path(@page.previous_page), class: "btn pagination-link"
      else
        disabled_pagination_control("Previous")
      end
    end

    def pagination_next_control
      if @page.has_next?
        link_to "Next", pagination_path(@page.next_page), class: "btn pagination-link"
      else
        disabled_pagination_control("Next")
      end
    end

    def pagination_page_indicator
      tag.p "Page #{@page.page_number} of #{@page.total_pages}", class: "pagination-page"
    end

    def disabled_pagination_control(text)
      tag.span text, class: "pagination-link-disabled"
    end

    def pagination_path(page_number)
      url_for(request.query_parameters.merge(page: page_number))
    end
end
