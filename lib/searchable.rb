module Searchable
  def self.indexed_models
    # Ensure descendants are fully loaded in rake/runtime contexts.
    Rails.application.eager_load!

    ApplicationRecord.descendants.select(&method(:model_is_indexed?))
  end

  def self.model_is_indexed?(model)
    model_includes_searchable?(model) && model.indexes?
  end

  def self.model_includes_searchable?(model)
    Searchable::Model.in?(model.ancestors)
  end

  def self.reindex_all!
    indexed_models.each(&:reindex_all!)
  end
end
