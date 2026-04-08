class ApplicationController < ActionController::Base
  include Authentication
  include Flashes

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :ensure_site_setup!

  private
    def ensure_site_setup!
      return if SiteSetup.complete?

      respond_to do |format|
        format.html do
          render template: "not_setup", status: :service_unavailable
        end

        format.atom do
          render plain: "There's nothing here yet.", status: :service_unavailable
        end

        format.any do
          render plain: "There's nothing here yet.", status: :service_unavailable
        end
      end
    end
end
