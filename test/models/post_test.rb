require "test_helper"

class PostTest < ActiveSupport::TestCase
  test "automatically sets the slug" do
    post = Post.new(title: "Automatic Slugs")

    assert_changes -> { post.slug }, from: nil, to: "automatic-slugs" do
      post.valid?
    end

    with_slug = Post.new(title: "Automatic Slugs", slug: "already-has-a-slug")

    assert_no_changes -> { with_slug.slug } do
      with_slug.valid?
    end
  end

  test "is invalid with a non-unique slug" do
    post = Post.new(title: "Non-Unique", slug: posts(:draft).slug)
    post.valid?

    assert post.errors.of_kind?(:slug, :taken)
  end

  test "is invalid with an incorrectly formatted slug" do
    post = Post.new(slug: "this.is.an.invalid.slug")
    post.valid?

    assert post.errors.of_kind?(:slug, :invalid)
  end

  test "is invalid with a slug that is too long" do
    slug = ([ "foobar" ] * 20).join("-")

    post = Post.new(slug: slug)
    post.valid?

    assert post.errors.of_kind?(:slug, :too_long)
  end

  test "is invalid if published_at is set before it is published" do
    post = posts(:draft)
    post.published_at = Time.current
    post.valid?

    assert post.errors.of_kind?(:published_at, :present)
  end

  test "is invalid if published without published_at" do
    post = posts(:published)
    post.published_at = nil
    post.valid?

    assert post.errors.of_kind?(:published_at, :blank)
  end

  test "cannot be published without content" do
    post = Post.new(title: "No Content", status: "published", published_at: Time.current)
    post.valid?

    assert post.errors.of_kind?(:content, :blank)
  end

  test "automatically sets published_at when status is changed" do
    published = posts(:published)

    assert_changes -> { published.published_at }, to: nil do
      published.status = "draft"
      published.valid?
    end

    draft = posts(:draft)

    assert_changes -> { draft.published_at }, from: nil do
      draft.status = "published"
      draft.valid?
    end
  end

  test "publishes via domain command" do
    draft = posts(:draft)

    assert_changes -> { draft.reload.status }, from: "draft", to: "published" do
      assert draft.publish!
    end
  end

  test "unpublishes via domain command" do
    published = posts(:published)

    assert_changes -> { published.reload.status }, from: "published", to: "draft" do
      assert published.unpublish!
    end
  end

  test "uses the slug as the param" do
    post = posts(:published)

    assert_equal post.slug, post.to_param
  end

  test "determines the default slug" do
    post = Post.new(title: "This is a Title")
    assert_equal "this-is-a-title", post.send(:default_slug)

    long_title = "This is a Really, Really, Really, Really, Really, Really, Truly Very Long Title"
    post = Post.new(title: long_title)
    assert_equal "this-is-a-really-really-really-really-really-reall", post.send(:default_slug)
  end

  test "ordered_for_display excludes drafts and orders by pinned then published_at desc" do
    ordered_posts = Post.ordered_for_display.to_a

    expected_order = [
      posts(:pinned_newer),
      posts(:pinned_older),
      posts(:pinned),
      posts(:pending_email),
      posts(:unpinned_newer),
      posts(:emailed),
      posts(:unpinned_older),
      posts(:published)
    ]

    assert_equal expected_order, ordered_posts
    assert_not_includes ordered_posts, posts(:draft)
  end
end
