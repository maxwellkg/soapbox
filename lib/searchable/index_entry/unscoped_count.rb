module Searchable::IndexEntry::UnscopedCount
  # Searchable::IndexEntry default scope adds a custom SELECT for `rowid`.
  # Aggregates should ignore that SELECT to avoid SQL issues in count queries.
  def count(column_name = nil)
    unscope!(:select)
    super
  end
end
