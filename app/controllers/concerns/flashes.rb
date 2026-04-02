module Flashes
  extend ActiveSupport::Concern

  included do
    add_flash_types :success, :error
  end

  private
    def flash_success(message, now: false)
      set_flash(:success, message, now:)
    end

    def flash_error(message, now: false)
      set_flash(:error, message, now:)
    end

    def flash_alert(message, now: false)
      set_flash(:alert, message, now:)
    end

    def flash_notice(message, now: false)
      set_flash(:notice, message, now:)
    end

    def set_flash(type, message, now: false)
      flash_target = now ? flash.now : flash
      flash_target[type] = message
    end
end
