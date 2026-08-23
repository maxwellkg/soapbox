module Subscriber::Unsubscribable
  extend ActiveSupport::Concern

  included do
    generates_token_for :unsubscribe
  end

  class_methods do
    def find_by_unsubscribe_token!(token)
      find_by_unsubscribe_token(token) ||
        raise(ActiveRecord::RecordNotFound.new("Could not find Subscriber with unsubscribe token = #{token}"))
    end

    def find_by_unsubscribe_token(token)
      find_by_token_for(:unsubscribe, token)
    end
  end

  def unsubscribe_token
    generate_token_for(:unsubscribe)
  end
end
