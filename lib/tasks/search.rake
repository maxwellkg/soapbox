namespace :search do
  desc "Reindex all search entries"
  task reindex_all: :environment do
    models = Searchable.indexed_models
    Searchable.reindex_all!

    puts "Reindexed search for #{models.size} model(s):"
    models.each { |model| puts "- #{model}" }
  end
end
