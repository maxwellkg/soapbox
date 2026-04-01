module Searchable::FullText::Searching
  extend ActiveSupport::Concern

  class_methods do
    def full_text_search_on(attribute, as: nil)
      search_name = as || attribute
      full_text_search(search_name, on: [ attribute ])
    end

    def full_text_search(search_name, on:)
      search_method_name = method_name_for_search(search_name)

      track_indexed_search_fields(on)
      track_full_text_search_method(search_method_name)

      define_indexed_search_method(search_method_name, on)
    end

    private
      def track_indexed_search_fields(search_fields)
        self.indexed_search_fields = (indexed_search_fields | search_fields.map(&:to_sym))
      end

      def track_full_text_search_method(search_method_name)
        self.full_text_search_methods = (full_text_search_methods | [ search_method_name.to_sym ])
      end

      def define_indexed_search_method(method_name, search_fields)
        define_indexed_search_method_on_extensions(method_name, search_fields)
        define_indexed_search_method_on_self(method_name)
      end

      def define_indexed_search_method_on_extensions(method_name, search_fields)
        scopable_extensions_module.define_method(method_name) do |search_term, order: "rank"|
          return all if search_term.blank?

          # Drop IndexEntry's rowid-select default scope before merging into the
          # model relation to avoid ambiguous rowid selection in joined SQL.
          search_index_scope = Searchable::IndexEntry
            .unscope(:select)
            .for_fields(search_fields)
            .matching(search_term)

          joins(:search_index_entries)
            .merge(search_index_scope)
            .order(order)
            .distinct
        end
      end

      def define_indexed_search_method_on_self(method_name)
        define_singleton_method(method_name) do |search_term, **options|
          all.public_send(method_name, search_term, **options)
        end
      end
  end
end
