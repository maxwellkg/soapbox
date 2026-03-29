require "test_helper"

class BlogTest < ActiveSupport::TestCase
  test "instance returns the singleton blog" do
    assert_equal blogs(:instance), Blog.instance
  end

  test "instance? returns true when blog exists" do
    assert Blog.instance?
  end

  test "instance? returns false when no blog exists" do
    Blog.delete_all

    assert_not Blog.instance?
  end

  test "instance! raises when no blog exists" do
    Blog.delete_all

    assert_raises(ActiveRecord::RecordNotFound) { Blog.instance! }
  end

  test "requires a title" do
    blog = blogs(:instance)
    blog.title = nil

    assert_not blog.valid?
    assert blog.errors.of_kind?(:title, :blank)

    blog.title = "Soapbox"
    assert blog.valid?
  end

  test "rejects creating a second blog at the application layer" do
    blog = Blog.new(title: "Second Blog")

    assert_not blog.valid?
    assert blog.errors.of_kind?(:base, :singleton_violation)
  end

  test "rejects creating a second blog at the db layer" do
    blog = Blog.new(title: "Second Blog")

    assert_db_constraint_violation do
      blog.save!(validate: false)
    end
  end

  private
    def assert_db_constraint_violation
      assert_raises(ActiveRecord::StatementInvalid, ActiveRecord::RecordNotUnique) { yield }
    end
end
