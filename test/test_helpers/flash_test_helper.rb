module FlashTestHelper
  def assert_flash_message(text, key: nil)
    if key.present?
      assert_equal text, flash[key]
    else
      assert_includes flash.to_hash.values.compact, text
    end

    assert_select ".flash-message", /#{Regexp.escape(text)}/
  end
end
