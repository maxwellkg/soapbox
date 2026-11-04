Rails.application.config.after_initialize do
  Premailer::Rails.config[:strategies] = [
    ThemeCSSLoader,
    :filesystem,
    :asset_pipeline,
    :propshaft,
    :network
  ]

  # Resolved CSS varies with the blog's theme, which can change within a
  # process's lifetime, so each delivery must re-read and resolve the email CSS.
  Premailer::Rails::CSSHelper.singleton_class.prepend(
    Module.new do
      def cache_enabled? = false
    end
  )
end
