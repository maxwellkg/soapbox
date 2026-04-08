namespace :site do
  desc "Create required singleton records for first run"
  task setup: :environment do
    abort("Site setup failed.") unless SiteSetup.run
  end
end
