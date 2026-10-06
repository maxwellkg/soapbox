class Searchable::IndexEntry < ActiveRecord::Base
  self.table_name = "search_index_entries"

  # SQLite FTS virtual tables do not include `rowid` in `SELECT *`.
  # Select it by default so Active Record always has the virtual-table id.
  default_scope -> { select("*, rowid") }

  attribute :rowid
  self.primary_key = :rowid

  scope :for_model, ->(model) { where(indexable_type: model.to_s) }
  scope :for_fields, ->(fields) { where(field: fields) }
  scope :matching, ->(search_term) { where("#{table_name} MATCH ?", fts_quoted_term(search_term)) }

  belongs_to :indexable, polymorphic: true

  class << self
    # This is SQLite FTS query quoting, not SQL quoting.
    # Escape embedded double quotes and wrap as a literal MATCH term.
    # Example input: hello "world"
    # SQL uses: WHERE search_index_entries MATCH '"hello ""world"""'
    def fts_quoted_term(search_term)
      escaped_term = search_term.to_s.gsub('"', '""')
      "\"#{escaped_term}\""
    end

    private
      def relation
        super.extending(UnscopedCount)
      end
  end
end
