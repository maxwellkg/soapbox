module FlashesHelper
  def flashes_tf_id
    "flashes"
  end

  def flash_message_class(type)
    case type.to_sym
    when :success
      "flash-message flash-success"
    when :error
      "flash-message flash-error"
    when :notice
      "flash-message flash-notice"
    when :alert
      "flash-message flash-alert"
    else
      "flash-message flash-neutral"
    end
  end

  def flash_message_role(type)
    type.to_sym.in?([ :alert, :error ]) ? "alert" : "status"
  end

  def flash_message_prefix(type)
    case type.to_sym
    when :success
      "Success"
    when :error
      "Error"
    when :alert
      "Alert"
    when :notice
      "Notice"
    else
      "Message"
    end
  end
end
