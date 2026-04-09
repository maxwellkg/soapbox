require "test_helper"

class Pagination::PageTest < ActiveSupport::TestCase
  test "uses default records per page when given non-positive value" do
    page = Pagination::Page.new(pagination_fixture_posts_query, page_number: 1, records_per_page: 0)

    assert_equal Pagination::Page::DEFAULT_RECORDS_PER_PAGE, page.records_per_page
  end

  test "returns one total page when query has no matching records" do
    page = Pagination::Page.new(Post.none, page_number: 1)

    assert_equal 1, page.total_pages
    assert page.first?
    assert page.last?
    assert_not page.has_previous?
    assert_not page.has_next?
  end

  test "calculates total pages from record count and records per page" do
    page = Pagination::Page.new(pagination_fixture_posts_query, page_number: 1)

    assert_equal 21, page.unpaginated_record_count
    assert_equal 2, page.total_pages
  end

  test "clamps page number below first page to one" do
    page = Pagination::Page.new(pagination_fixture_posts_query, page_number: 0)

    assert_equal 1, page.page_number
    assert page.first?
    assert_not page.has_previous?
  end

  test "clamps page number above total pages to last page" do
    page = Pagination::Page.new(pagination_fixture_posts_query, page_number: 999)

    assert_equal 2, page.page_number
    assert page.last?
    assert_not page.has_next?
  end

  test "returns records and navigation for each page" do
    first_page = Pagination::Page.new(pagination_fixture_posts_query, page_number: 1)
    second_page = Pagination::Page.new(pagination_fixture_posts_query, page_number: 2)

    assert_equal 20, first_page.records.count
    assert_equal 1, second_page.records.count

    assert_nil first_page.previous_page
    assert_equal 2, first_page.next_page

    assert_equal 1, second_page.previous_page
    assert_nil second_page.next_page
  end

  private
    def pagination_fixture_posts_query
      Post.where("slug LIKE ?", "pagination-fixture-post-%").order(published_at: :desc)
    end
end
