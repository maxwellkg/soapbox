require "test_helper"

class AuthorTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    author = Author.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", author.email_address)
  end

  test "full_name combines first and last names" do
    assert_equal "Jane Doe", authors(:one).full_name
  end

  test "instance returns the singleton author" do
    assert_equal authors(:one), Author.instance
  end

  test "instance? returns true when author exists" do
    assert Author.instance?
  end

  test "instance? returns false when no author exists" do
    Author.delete_all

    assert_not Author.instance?
  end

  test "instance! raises when no author exists" do
    Author.delete_all

    assert_raises(ActiveRecord::RecordNotFound) { Author.instance! }
  end

  test "authenticates with valid credentials" do
    author = authors(:one)

    assert_equal author, Author.authenticate_by(email_address: author.email_address, password: "password")
  end

  test "requires a first name" do
    author = authors(:one)
    author.first_name = nil

    assert_not author.valid?
    assert author.errors.of_kind?(:first_name, :blank)

    author.first_name = "Jane"
    assert author.valid?
  end

  test "requires a last name" do
    author = authors(:one)
    author.last_name = nil

    assert_not author.valid?
    assert author.errors.of_kind?(:last_name, :blank)

    author.last_name = "Doe"
    assert author.valid?
  end

  test "requires an email address" do
    author = authors(:one)
    author.email_address = nil

    assert_not author.valid?
    assert author.errors.of_kind?(:email_address, :blank)

    author.email_address = "one@example.com"
    assert author.valid?
  end

  test "requires a valid email address format" do
    author = authors(:one)
    author.email_address = "not-an-email"

    assert_not author.valid?
    assert author.errors.of_kind?(:email_address, :invalid)

    author.email_address = "one@example.com"
    assert author.valid?
  end

  test "is valid when all validations are met" do
    author = authors(:one)

    assert author.valid?
  end

  test "rejects creating a second author (at the application layer)" do
    author = Author.new(email_address: "second@example.com", password: "password")

    assert_not author.valid?
    assert author.errors.of_kind?(:base, :singleton_violation)
  end

  test "rejects creating a second author (at the db layer)" do
    author = Author.new(email_address: "second@example.com", password: "password")

    assert_db_constraint_violation do
      author.save!(validate: false)
    end
  end

  private
    def assert_db_constraint_violation
      assert_raises(ActiveRecord::StatementInvalid, ActiveRecord::RecordNotUnique) { yield }
    end
end
