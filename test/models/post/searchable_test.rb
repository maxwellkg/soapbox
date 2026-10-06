require "test_helper"

class Post::SearchableTest < ActiveSupport::TestCase
  setup do
    Post.reindex_all!
  end

  test "one search covers title, summary, and content" do
    post = posts(:draft)
    post.update!(title: "Orbital Report", summary: "<p>nebula summary token</p>", content: "<p>nebula content token</p>")

    assert_includes Post.search_title_summary_and_content("orbital").pluck(:id), post.id
    assert_includes Post.search_title_summary_and_content("nebula").pluck(:id), post.id
  end

  test "searches the plain text rendered from markdown" do
    post = posts(:draft)
    post.update!(content: "# Heading Token\n\n**body token**")

    assert_includes Post.search_title_summary_and_content("body token").pluck(:id), post.id
    assert_empty Post.search_title_summary_and_content("strong").pluck(:id)
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

  test "changing content automatically reindexes the derived plain text" do
    post = posts(:published)

    post.update!(content: "<p>Content Token After Edit</p>")

    assert_equal [ "Content Token After Edit" ],
                 Searchable::IndexEntry.for_model(Post).where(indexable_id: post.id, field: "plain_text_content").pluck(:content)
  end

  test "destroy deletes search index entries" do
    post = posts(:published)
    post.reindex

    assert post.search_index_entries.any?

    post.destroy!

    assert_equal 0, Searchable::IndexEntry.for_model(Post).where(indexable_id: post.id).count
  end
end
