class Blog < ApplicationRecord
  has_rich_text :description, store_if_blank: false

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

  def author
    Author.instance!
  end

  def as_atom_feed_xml
    atom_feed.to_xml
  end

  def atom_feed
    feed.atom_feed
  end

  def feed
    @feed ||= Blog::Feed.new(self)
  end

  private
    def single_instance_only
      if self.class.instance?
        errors.add(:base, :singleton_violation, message: "Only one blog is allowed")
      end
    end
end
