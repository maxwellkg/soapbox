module Searchable::Model
  extend ActiveSupport::Concern

  included do
    include Searchable::Basic
    include Searchable::FullText

    scope :search, ->(**searches) do
      searches.reduce(all) do |relation, (search_name, term)|
        relation.public_send(method_name_for_search(search_name), term)
      end
    end
  end

  class_methods do
    def method_name_for_search(search_name)
      "search_#{search_name}"
    end

    def search_methods
      [ *basic_search_methods, *full_text_search_methods ]
    end

    def database_backed_attribute?(attribute_name)
      canonical_attribute_name(attribute_name.to_s).in?(column_names)
    end

    private
      def canonical_attribute_name(attribute_name)
        if alias_name = attribute_aliases[attribute_name]
          canonical_attribute_name(alias_name)
        else
          attribute_name
        end
      end
  end
end
