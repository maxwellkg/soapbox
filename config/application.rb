require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Soapbox
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[rails_ext assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # ThemeCSSLoader expands theme variables for email and must be registered
    # ahead of the stock premailer-rails strategies. It is referenced here
    # rather than in config/initializers because :setup_main_autoloader runs
    # after config/initializers, when Zeitwerk autoload constants do not yet resolve.
    initializer "soapbox.premailer_theme_css", after: :setup_main_autoloader do
      Premailer::Rails.config[:strategies] = [
        ThemeCSSLoader,
        :filesystem, :asset_pipeline, :propshaft, :network
      ]

      # Resolved CSS varies with the blog's theme, which can change within a
      # process's lifetime, so premailer-rails' per-URL stylesheet cache is
      # disabled: each delivery re-reads and re-resolves the few KB of email
      # CSS, which is noise next to Premailer's inlining work.
      Premailer::Rails::CSSHelper.singleton_class.prepend(
        Module.new do
          def cache_enabled? = false
        end
      )
    end
  end
end
