class Post < ApplicationRecord
  include Post::Emailing
  include Post::Searchable

  MAX_SLUG_LENGTH = 50
  STATUSES = %w[ draft published ]

  has_many :emails, class_name: "PostEmail", dependent: :destroy
  has_rich_text :summary, store_if_blank: false
  has_rich_text :content, store_if_blank: false

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
    validates :content, presence: true
    validates :published_at, presence: { message: "must be set when the post is published" }
  end

  before_validation :set_default_slug, if: :title_present_and_slug_blank?
  before_validation :set_published_at, if: :will_save_change_to_status?

  def to_param
    slug
  end

  def author
    Author.instance!
  end

  def publish!
    update(status: "published")
  end

  def unpublish!
    update(status: "draft")
  end

  private
    def set_published_at
      self.published_at = published? ? Time.current : nil
    end

    def title_present_and_slug_blank?
      title.present? && slug.blank?
    end

    def set_default_slug
      self.slug = default_slug
    end

    def default_slug
      title.parameterize.first(MAX_SLUG_LENGTH)
    end
end
