require "test_helper"

class SearchableTest < ActiveSupport::TestCase
  test "indexed_models returns searchable indexed models" do
    models = Searchable.indexed_models

    assert_includes models, Post
    assert_not_includes models, Subscriber
  end

  test "reindex_all! reindexes all indexed models" do
    Searchable::IndexEntry.for_model(Post).delete_all

    Searchable.reindex_all!

    assert_operator Searchable::IndexEntry.for_model(Post).count, :>, 0
  end
end
