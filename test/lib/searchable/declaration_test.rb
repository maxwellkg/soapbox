require "test_helper"

class SearchableSample < ApplicationRecord
  self.table_name = "sessions"

  include Searchable::Model

  full_text_search_on :user_agent
  full_text_search_on :ip_address, as: :address
  full_text_search :agent_and_address, on: %i[ user_agent ip_address ]

  basic_search :who, on: %i[ user_agent ip_address ]
end

class Searchable::DeclarationTest < ActiveSupport::TestCase
  setup do
    @navigator = create_sample(user_agent: "Firefox Navigator", ip_address: "10.0.0.1")
    @explorer = create_sample(user_agent: "Safari Navigator", ip_address: "192.168.0.7")
  end

  test "singular declaration searches the attribute it names" do
    assert_equal [ @navigator.id ], SearchableSample.search_user_agent("firefox").pluck(:id)
  end

  test "as names the method without changing the indexed field" do
    assert_equal [ @explorer.id ], SearchableSample.search_address("192").pluck(:id)
    assert_not SearchableSample.respond_to?(:search_ip_address)

    fields = Searchable::IndexEntry.for_model(SearchableSample)
                                  .where(indexable_id: @explorer.id)
                                  .pluck(:field)

    assert_equal %w[ ip_address user_agent ], fields.sort
  end

  test "plural declaration searches every attribute in its list" do
    assert_equal [ @navigator.id, @explorer.id ].sort,
                 SearchableSample.search_agent_and_address("navigator").pluck(:id).sort
    assert_equal [ @navigator.id ], SearchableSample.search_agent_and_address("firefox").pluck(:id)
  end

  test "a search method does not match text held by another field" do
    assert_empty SearchableSample.search_user_agent("192").pluck(:id)
  end

  test "blank terms return the relation unfiltered" do
    assert_equal SearchableSample.pluck(:id).sort, SearchableSample.search_agent_and_address("").pluck(:id).sort
    assert_equal SearchableSample.pluck(:id).sort, SearchableSample.search_who("").pluck(:id).sort
  end

  test "order can be overridden" do
    results = SearchableSample.search_agent_and_address("navigator", order: "sessions.id asc").pluck(:id)

    assert_equal results.sort, results
  end

  test "basic search matches any column in its list" do
    assert_equal [ @navigator.id ], SearchableSample.search_who("firefox").pluck(:id)
    assert_equal [ @explorer.id ], SearchableSample.search_who("192.168").pluck(:id)
  end

  private
    def create_sample(user_agent:, ip_address:)
      SearchableSample.create!(author_id: authors(:instance).id, user_agent:, ip_address:)
    end
end
