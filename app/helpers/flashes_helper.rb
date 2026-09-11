module FlashesHelper
  def flashes_frame_id
    "flashes"
  end

  def flash_message_class(type)
    "flash-message flash-#{normalized_flash_type(type)}"
  end

  def flash_message_role(type)
    flash_message_alert_role?(type) ? "alert" : "status"
  end

  def flash_message_prefix(type)
    if recognized_flash_type?(type)
      type.to_s.titleize
    else
      "Message"
    end
  end

  def flash_messages_display
    render partial: "shared/flash_message", collection: flash_collection, as: :flash
  end

  def update_flashes
    turbo_stream.update flashes_frame_id do
      flash_messages_display
    end
  end

  private
    def normalized_flash_type(type)
      recognized_flash_type?(type) ? type.to_s : "neutral"
    end

    def recognized_flash_type?(type)
      type.to_sym.in?(%i[ success error notice alert ])
    end

    def flash_message_alert_role?(type)
      type.to_sym.in?(%i[ alert error ])
    end

    def flash_collection
      flash.map { |type, message| { type:, message: } }
    end
end
