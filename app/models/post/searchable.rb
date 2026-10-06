module Post::Searchable
  extend ActiveSupport::Concern

  included do
    include Searchable::Model

    full_text_search :title_summary_and_content, on: %i[ title plain_text_summary plain_text_content ]
  end

  def plain_text_summary
    ActionText::Content.new(summary.to_html).to_plain_text
  end

  def saved_change_to_plain_text_summary?
    summary.saved_change_to_content?
  end

  def plain_text_content
    ActionText::Content.new(content.to_html).to_plain_text
  end

  def saved_change_to_plain_text_content?
    content.saved_change_to_content?
  end
end
