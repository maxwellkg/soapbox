module Authorable
  extend ActiveSupport::Concern

  def author
    @author ||= Author.instance!
  end
end
