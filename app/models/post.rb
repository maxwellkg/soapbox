class Post < ApplicationRecord
  include Authorable
  include Post::Emailing
  include Post::Searchable

  MAX_SLUG_LENGTH = 50
  STATUSES = %w[ draft published ]

  has_markdown :summary
  has_markdown :content

  enum :status, STATUSES.index_with(&:itself), validate: true

  scope :ordered_for_display, -> { published.order(pinned: :desc, published_at: :desc) }

  validates :title, presence: true

  validates :slug,
            presence: true,
            uniqueness: true,
            format: { with: /\A[a-z0-9]+(-[a-z0-9]+)*\z/ },
            length: { maximum: MAX_SLUG_LENGTH }

  validates :published_at,
            absence: { message: "must be blank unless the post is published" },
            unless: :published?

  with_options if: :published? do
    validate :published_posts_must_have_content
    validates :published_at, presence: { message: "must be set when the post is published" }
  end

  before_validation :set_default_slug, if: -> { title.present? && slug.blank? }
  before_validation :set_published_at, if: :will_save_change_to_status?

  def to_param
    slug
  end

  def publish!
    update(status: "published")
  end

  def unpublish!
    self.status = :draft
    self.email_status = :not_started if email_status_pending?

    save
  end

  def excerpt
    Excerpt.new(self).text
  end

  private
    def published_posts_must_have_content
      if content.content.blank?
        errors.add(:content, :blank)
      end
    end

    def set_published_at
      self.published_at = published? ? Time.current : nil
    end

    def set_default_slug
      self.slug = default_slug
    end

    def default_slug
      title.parameterize.first(MAX_SLUG_LENGTH)
    end
end
