class Current < ActiveSupport::CurrentAttributes
  attribute :session
  delegate :author, to: :session, allow_nil: true
end
