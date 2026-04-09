require "test_helper"

class Admin::PostsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @author = authors(:one)
  end

  test "redirects unauthenticated access across post admin routes" do
    post_record = posts(:draft)

    get admin_posts_path
    assert_redirected_to new_session_path

    get admin_post_path(post_record)
    assert_redirected_to new_session_path

    get new_admin_post_path
    assert_redirected_to new_session_path

    get edit_admin_post_path(post_record)
    assert_redirected_to new_session_path

    post admin_posts_path, params: { post: { title: "Test" } }
    assert_redirected_to new_session_path

    patch admin_post_path(post_record), params: { post: { title: "Updated" } }
    assert_redirected_to new_session_path

    delete admin_post_path(post_record)
    assert_redirected_to new_session_path
  end

  test "index lists posts" do
    sign_in_as(@author)

    get admin_posts_path

    assert_response :success
    assert_select "h1", "Posts"

    assert_select "h2", Post.count

    Post.all.each do |post|
      assert_select "h2", text: post.title
    end
  end

  test "index searches posts" do
    sign_in_as(@author)
    Post.reindex_all!

    get admin_posts_path, params: { search: "email" }

    assert_response :success
    assert_select "h2", count: 2
    assert_select "h2", text: posts(:emailed).title
    assert_select "h2", text: posts(:pending_email).title
    assert_select "p", text: "2 matching posts"

    get admin_posts_path, params: { search: "foobar" }
    assert_select "h2", count: 0
    assert_select "p", text: "0 matching posts"

    get admin_posts_path, params: { search: "pinned newer" }
    assert_select "h2", count: 1
    assert_select "p", text: "1 matching post"
  end

  test "index filters posts by status" do
    sign_in_as(@author)

    get admin_posts_path, params: { status: "draft" }
    assert_response :success
    assert_select "h2", count: Post.draft.count

    get admin_posts_path, params: { status: "published" }
    assert_response :success
    assert_select "h2", count: Post.published.count

    get admin_posts_path, params: { status: "" }
    assert_response :success
    assert_select "h2", count: Post.count

    get admin_posts_path, params: { status: "foobar" }
    assert_response :success
    assert_select "h2", count: 0
  end

  test "index combines search and status filter" do
    sign_in_as(@author)
    Post.reindex_all!

    get admin_posts_path, params: { search: "email", status: "published" }

    assert_response :success
    assert_select "h2", count: 2
    assert_select "h2", text: posts(:emailed).title
    assert_select "h2", text: posts(:pending_email).title

    get admin_posts_path, params: { search: "email", status: "draft" }

    assert_response :success
    assert_select "h2", count: 0
  end

  test "show displays the post" do
    sign_in_as(@author)
    post_record = posts(:published)

    get admin_post_path(post_record)

    assert_response :success
    assert_select "turbo-cable-stream-source"
    assert_select "h1", post_record.title
    assert_select "#post-admin-notice"
    assert_includes response.body, post_record.content.body.to_s
  end

  test "new renders a form" do
    sign_in_as(@author)

    get new_admin_post_path

    assert_response :success
    assert_select "h1", "New Post"
    assert_select "form[action=?][method=?]", admin_posts_path, "post"
  end

  test "edit renders a form" do
    sign_in_as(@author)
    post_record = posts(:draft)

    get edit_admin_post_path(post_record)

    assert_response :success
    assert_select "h1", "Edit Post"
    assert_select "form[action=?]", admin_post_path(post_record) do
      assert_select "input[type=?][name=?][value=?]", "hidden", "_method", "patch"
    end
  end

  test "create creates a post" do
    sign_in_as(@author)

    assert_difference -> { Post.count }, 1 do
      post admin_posts_path, params: {
        post: {
          title: "A New Admin Post",
          slug: "a-new-admin-post",
          pinned: "1",
          summary: "<div>Summary text</div>",
          content: "<div>New content</div>"
        }
      }
    end

    created = Post.order(:id).last
    assert_redirected_to admin_post_path(created)
    assert_equal "Post was successfully created.", flash[:success]
    assert_equal "a-new-admin-post", created.slug
    assert created.pinned?
  end

  test "create re-renders when invalid" do
    sign_in_as(@author)

    assert_no_difference -> { Post.count } do
      post admin_posts_path, params: {
        post: {
          slug: "missing-title",
          content: "<div>Content without a title</div>"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "h1", "New Post"
    assert_select ".admin-form-errors"
  end

  test "update changes the post" do
    sign_in_as(@author)
    post_record = posts(:draft)

    assert_changes -> { post_record.reload.title }, to: "Updated Draft Title" do
      patch admin_post_path(post_record), params: {
        post: {
          title: "Updated Draft Title",
          pinned: "1"
        }
      }
    end

    assert_redirected_to admin_post_path(post_record)
    assert_equal "Post was successfully updated.", flash[:success]
    assert post_record.reload.pinned?
  end

  test "update re-renders when invalid" do
    sign_in_as(@author)
    post_record = posts(:draft)

    assert_no_changes -> { post_record.reload.title } do
      patch admin_post_path(post_record), params: {
        post: {
          title: ""
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "h1", "Edit Post"
    assert_select ".admin-form-errors"
  end

  test "destroy deletes a post" do
    sign_in_as(@author)
    post_record = posts(:draft)

    assert_difference -> { Post.count }, -1 do
      delete admin_post_path(post_record)
    end

    assert_redirected_to admin_posts_path
    assert_equal "Post was successfully deleted.", flash[:success]
  end
end
