module Searchable
  def self.indexed_models
    # Ensure descendants are fully loaded in rake/runtime contexts.
    Rails.application.eager_load!

    ApplicationRecord.descendants.select do |model|
      model <= Searchable::Model && model.indexes?
    end
  end

  def self.reindex_all!
    indexed_models.each(&:reindex_all!)
  end
end
