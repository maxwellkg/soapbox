module Searchable::FullText::Indexing
  extend ActiveSupport::Concern

  class_methods do
    def reindex_all!(*fields)
      find_each do |record|
        record.reindex(*fields)
      end
    end

    def indexes?
      indexed_search_fields.any?
    end

    def indexed?
      Searchable::IndexEntry.for_model(self).any?
    end

    def indexed_search_field?(field_name)
      field_name.to_sym.in?(indexed_search_fields)
    end
  end

  def reindex(*fields)
    fields_to_reindex = fields.empty? ? indexed_search_fields : fields

    check_fields_to_reindex(*fields_to_reindex)

    transaction do
      tear_down_indexed_fields(*fields_to_reindex)
      build_indexed_fields(*fields_to_reindex)
    end
  end

  private
    def tear_down_indexed_fields(*fields_to_reindex)
      search_index_entries.where(field: fields_to_reindex).delete_all
    end

    def build_indexed_fields(*fields_to_reindex)
      fields_to_reindex.each { |field| reindex_field(field) }
    end

    def reindex_field(field)
      field_content = content_for_indexed_field(field)
      search_index_entries.create!(field: field, content: field_content) unless field_content.blank?
    end

    def content_for_indexed_field(field)
      public_send(field)
    end

    def reindex_changed_fields
      reindex(*changed_indexed_search_fields)
    end

    def saved_change_to_any_indexed_search_field?
      changed_indexed_search_fields.any?
    end

    def changed_indexed_search_fields
      indexed_search_fields.select { |field| indexed_search_field_changed?(field) }
    end

    def indexed_search_field_changed?(field)
      public_send("saved_change_to_#{field}?")
    end

    def check_fields_to_reindex(*fields)
      unless fields.all? { |field| indexed_search_field?(field) }
        raise "Invalid fields for reindex"
      end
    end
end
