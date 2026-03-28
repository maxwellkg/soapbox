require "test_helper"

class SessionTest < ActiveSupport::TestCase
  test "requires an author" do
    session = Session.new

    assert_not session.valid?
    assert_includes session.errors[:author], "must exist"
  end

  test "belongs to author" do
    author = authors(:one)
    session = author.sessions.create!(user_agent: "test", ip_address: "127.0.0.1")

    assert_equal author, session.author
  end
end
