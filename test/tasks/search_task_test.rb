require "test_helper"
require "rake"

class SearchTaskTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
    Rake::Task["search:reindex_all"].reenable
  end

  test "search:reindex_all rebuilds post entries" do
    Searchable::IndexEntry.for_model(Post).delete_all

    Rake::Task["search:reindex_all"].invoke

    assert_operator Searchable::IndexEntry.for_model(Post).count, :>, 0
  end
end
