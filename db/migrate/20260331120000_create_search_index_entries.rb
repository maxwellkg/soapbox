class CreateSearchIndexEntries < ActiveRecord::Migration[8.1]
  def change
    create_virtual_table :search_index_entries, :fts5,
                         [
                           "indexable_type UNINDEXED",
                           "indexable_id UNINDEXED",
                           "field UNINDEXED",
                           "content",
                           "tokenize = 'porter'"
                         ]
  end
end
