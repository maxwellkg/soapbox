module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_author

    def connect
      set_current_author || reject_unauthorized_connection
    end

    private
      def set_current_author
        if session = Session.find_by(id: cookies.signed[:session_id])
          self.current_author = session.author
        end
      end
  end
end
