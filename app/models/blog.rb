class Blog < ApplicationRecord
  include Authorable

  has_markdown :description
  has_one_attached :site_image
  attribute :should_remove_site_image, :boolean, default: false

  before_save :remove_site_image, if: :should_remove_site_image?

  validate :single_instance_only, on: :create
  validates :title, presence: true

  class << self
    def instance
      first
    end

    def instance!
      first!
    end

    def instance?
      exists?
    end
  end

  def feed_xml
    feed.as_xml
  end

  def feed
    @feed ||= Blog::Feed.new(self)
  end

  private
    def remove_site_image
      site_image.purge if site_image.attached?
      self.should_remove_site_image = false
      self
    end

    def single_instance_only
      if self.class.instance?
        errors.add(:base, :singleton_violation, message: "Only one blog is allowed")
      end
    end
end
