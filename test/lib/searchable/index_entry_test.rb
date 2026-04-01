require "test_helper"

class Searchable::IndexEntryTest < ActiveSupport::TestCase
  test "includes rowid on selected records" do
    post = posts(:draft)
    post.reindex(:title)

    entry = post.search_index_entries.first

    assert_not_nil entry.rowid
  end

  test "count works with rowid default scope" do
    assert_nothing_raised do
      Searchable::IndexEntry.count
    end
  end

  test "association count works with rowid default scope" do
    post = posts(:published)
    post.reindex(:title)

    assert_nothing_raised do
      post.search_index_entries.count
    end
  end

  test "matching handles embedded quotes" do
    post = posts(:draft)
    post.update!(title: "Quoted \"token\" title")
    post.reindex(:title)

    assert_nothing_raised do
      Searchable::IndexEntry.for_model(Post).matching("\"token\"").load
    end
  end
end
