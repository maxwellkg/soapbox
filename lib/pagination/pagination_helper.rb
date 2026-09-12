module Pagination::PaginationHelper
  def render_pagination_controls
    return unless show_pagination_controls?

    tag.nav class: "pagination", "aria-label": "Pagination" do
      safe_join([ pagination_previous_control, pagination_page_indicator, pagination_next_control ])
    end
  end

  private
    PREVIOUS_PAGE_LABEL = "Previous"
    NEXT_PAGE_LABEL = "Next"

    def show_pagination_controls?
      more_than_one_page?
    end

    def more_than_one_page?
      @page.others?
    end

    def pagination_previous_control
      @page.has_previous? ? link_to_previous_page : disabled_pagination_control(PREVIOUS_PAGE_LABEL)
    end

    def link_to_previous_page
      link_to PREVIOUS_PAGE_LABEL, pagination_path(@page.previous_page), class: "btn pagination-link"
    end

    def pagination_next_control
      @page.has_next? ? link_to_next_page : disabled_pagination_control(NEXT_PAGE_LABEL)
    end

    def link_to_next_page
      link_to NEXT_PAGE_LABEL, pagination_path(@page.next_page), class: "btn pagination-link"
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
