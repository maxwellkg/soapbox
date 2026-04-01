module Post::Searchable
  extend ActiveSupport::Concern

  included do
    include Searchable::Model

    full_text_search_on :title
    full_text_search_on :plain_text_summary, as: :summary
    full_text_search_on :plain_text_content, as: :content
    full_text_search :title_summary_and_content, on: %i[ title plain_text_summary plain_text_content ]
  end

  def plain_text_summary
    summary.body&.to_plain_text
  end

  def saved_change_to_plain_text_summary?
    summary.saved_change_to_body?
  end

  def plain_text_content
    content.body&.to_plain_text
  end

  def saved_change_to_plain_text_content?
    content.saved_change_to_body?
  end
end
