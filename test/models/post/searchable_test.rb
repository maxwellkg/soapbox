require "test_helper"

class Post::SearchableTest < ActiveSupport::TestCase
  setup do
    Post.reindex_all!
  end

  test "full text search on title" do
    results = Post.search_title("emailed")

    assert_includes results.pluck(:id), posts(:emailed).id
  end

  test "full text search supports terms with quotes" do
    post = posts(:draft)
    post.update!(title: "Quoted \"nebula\" title")

    results = Post.search_title("\"nebula\"")

    assert_includes results.pluck(:id), post.id
  end

  test "search scope routes to named search methods" do
    results = Post.search(title: "emailed")

    assert_includes results.pluck(:id), posts(:emailed).id
  end

  test "full text search on summary and content" do
    post = posts(:draft)
    post.update!(summary: "<p>orbital summary token</p>", content: "<p>nebula content token</p>")

    assert_includes Post.search_summary("orbital").pluck(:id), post.id
    assert_includes Post.search_content("nebula").pluck(:id), post.id
    assert_includes Post.search_title_summary_and_content("nebula").pluck(:id), post.id
  end

  test "full text search accepts explicit order override" do
    results = Post.search_title("post", order: "posts.id asc")

    assert_equal results.pluck(:id).sort, results.pluck(:id)
  end

  test "blank search terms return all" do
    assert_equal Post.all.pluck(:id).sort, Post.search_title("").pluck(:id).sort
  end

  test "reindex all creates title index entries for every post" do
    Searchable::IndexEntry.for_model(Post).delete_all

    Post.reindex_all!

    assert_equal Post.count, Searchable::IndexEntry.for_model(Post).where(field: "title").count
  end

  test "changing title automatically reindexes that title" do
    post = posts(:published)
    post.reindex(:title)

    post.update!(title: "Published Post Renamed For Search")

    assert_equal [ "Published Post Renamed For Search" ],
                 Searchable::IndexEntry.for_model(Post).where(indexable_id: post.id, field: "title").pluck(:content)
  end

  test "destroy deletes search index entries" do
    post = posts(:published)
    post.reindex

    assert post.search_index_entries.any?

    post.destroy!

    assert_equal 0, Searchable::IndexEntry.for_model(Post).where(indexable_id: post.id).count
  end
end
