class Author < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  validate :single_instance_only, on: :create
  validates :first_name, presence: true
  validates :last_name, presence: true

  validates :email_address,
            presence: true,
            format: { with: URI::MailTo::EMAIL_REGEXP }

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

  def full_name
    "#{first_name} #{last_name}"
  end

  private
    def single_instance_only
      if self.class.instance?
        errors.add(:base, :singleton_violation, message: "Only one author is allowed")
      end
    end
end
