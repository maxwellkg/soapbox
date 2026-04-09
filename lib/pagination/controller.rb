module Pagination::Controller
  extend ActiveSupport::Concern

  included do
    helper Pagination::PaginationHelper
  end

  private
    def paginate(query, records_per_page: nil)
      @page = Pagination::Page.new(
        query,
        **{
          page_number: page_number_param,
          records_per_page: records_per_page
        }.compact_blank
      )

      @page.records
    end

    def page_number_param
      number = params[:page].to_i

      number.positive? ? number : 1
    end
end
