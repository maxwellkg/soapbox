module Searchable::Basic
  extend ActiveSupport::Concern

  included do
    class_attribute :basic_search_methods, default: []
  end

  class_methods do
    def basic_search_on(attribute, as: nil)
      search_name = as || attribute
      basic_search(search_name, on: [ attribute ])
    end

    def basic_search(search_name, on:)
      check_attributes_for_basic_search(search_name, on)

      search_method_name = method_name_for_search(search_name)

      track_basic_search_method(search_method_name)
      define_basic_search_method(search_method_name, on)
    end

    private
      def track_basic_search_method(search_method_name)
        self.basic_search_methods = (basic_search_methods | [ search_method_name.to_sym ])
      end

      def check_attributes_for_basic_search(search_name, attributes)
        unless attributes.all? { |attribute| database_backed_attribute?(attribute) }
          raise "Invalid attributes for basic search #{search_name}"
        end
      end

      def define_basic_search_method(search_method_name, attributes)
        define_singleton_method(search_method_name) do |search_term|
          return all if search_term.blank?

          pattern = "%#{sanitize_sql_like(search_term.to_s)}%"

          conditions = attributes
            .map { |attribute| arel_table[attribute].matches(pattern) }
            .reduce(&:or)

          where(conditions)
        end
      end
  end
end
