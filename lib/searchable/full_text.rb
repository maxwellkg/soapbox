module Searchable::FullText
  extend ActiveSupport::Concern

  included do
    include Searchable::FullText::Searching
    include Searchable::FullText::Indexing

    class_attribute :indexed_search_fields, default: []
    class_attribute :full_text_search_methods, default: []

    has_many :search_index_entries, class_name: "Searchable::IndexEntry", as: :indexable, dependent: :delete_all

    # Reindex only on create/update; destroy cleanup is handled by
    # dependent: :delete_all on search_index_entries.
    after_commit :reindex_changed_fields, on: %i[ create update ], if: :saved_change_to_any_indexed_search_field?

    delegate :indexed_search_field?, to: :class
  end

  class_methods do
    private
      def relation
        super.extending(scopable_extensions_module)
      end

      def scopable_extensions_module
        @scopable_extensions_module ||= Module.new
      end
  end
end
