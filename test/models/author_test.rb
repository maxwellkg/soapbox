require "test_helper"

class AuthorTest < ActiveSupport::TestCase
  test "downcases and strips email_address" do
    author = Author.new(email_address: " DOWNCASED@EXAMPLE.COM ")
    assert_equal("downcased@example.com", author.email_address)
  end

  test "authenticates with valid credentials" do
    author = authors(:one)

    assert_equal author, Author.authenticate_by(email_address: author.email_address, password: "password")
  end

  test "rejects duplicate email addresses" do
    assert_db_constraint_violation do
      Author.create!(email_address: authors(:one).email_address, password: "password")
    end
  end

  test "rejects creating a second author" do
    assert_db_constraint_violation do
      Author.create!(email_address: "second@example.com", password: "password")
    end
  end

  private
    def assert_db_constraint_violation
      assert_raises(ActiveRecord::StatementInvalid, ActiveRecord::RecordNotUnique) { yield }
    end
end
