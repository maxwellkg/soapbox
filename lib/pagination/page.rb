class Pagination::Page
  DEFAULT_RECORDS_PER_PAGE = 20

  attr_reader :records_per_page

  def initialize(query, page_number:, records_per_page: DEFAULT_RECORDS_PER_PAGE)
    @query = query
    @requested_page_number = page_number
    @records_per_page = normalize_records_per_page(records_per_page)
  end

  def page_number
    @page_number ||= normalize_page_number
  end

  def first?
    page_number == 1
  end

  def last?
    page_number == total_pages
  end

  def has_previous?
    !first?
  end

  def has_next?
    !last?
  end

  def previous_page
    page_number - 1 if has_previous?
  end

  def next_page
    page_number + 1 if has_next?
  end

  def total_pages
    @total_pages ||= no_matching_records? ? 1 : calculated_total_pages
  end

  def records
    @records ||= @query.limit(records_per_page).offset(offset)
  end

  def unpaginated_record_count
    @unpaginated_record_count ||= @query.count
  end

  private
    def offset
      (page_number - 1) * records_per_page
    end

    def normalize_page_number
      if @requested_page_number < 1
        1
      elsif @requested_page_number > total_pages
        total_pages
      else
        @requested_page_number
      end
    end

    def normalize_records_per_page(value)
      number = value.to_i

      number.positive? ? number : DEFAULT_RECORDS_PER_PAGE
    end

    def no_matching_records?
      unpaginated_record_count.zero?
    end

    def calculated_total_pages
      (unpaginated_record_count.to_f / records_per_page).ceil
    end
end
