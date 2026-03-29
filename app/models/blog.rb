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

  private
    def single_instance_only
      errors.add(:base, "Only one blog is allowed") if self.class.instance?
    end
end
