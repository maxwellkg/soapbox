module Searchable::Controller
  extend ActiveSupport::Concern

  included do
    helper_method :search_term, :search_given?
  end

  private
    def search_given?
      search_term.present?
    end

    def search_term
      search_params[:search].presence
    end

    def search_params
      params.permit(:search)
    end
end
