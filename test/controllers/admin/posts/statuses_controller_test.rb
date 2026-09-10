require "test_helper"

class Admin::Posts::StatusesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @author = authors(:one)
  end

  test "redirects unauthenticated publish and unpublish" do
    draft = posts(:draft)
    published = posts(:published)

    patch publish_admin_post_path(draft)
    assert_redirected_to new_session_path

    patch unpublish_admin_post_path(published)
    assert_redirected_to new_session_path
  end

  test "publishes a draft post" do
    sign_in_as(@author)
    post_record = posts(:draft)

    assert_changes -> { post_record.reload.status }, from: "draft", to: "published" do
      patch publish_admin_post_path(post_record)
    end

    assert_redirected_to admin_post_path(post_record)
    assert_equal "Post was successfully published.", flash[:success]
  end

  test "unpublishes a published post" do
    sign_in_as(@author)
    post_record = posts(:published)

    assert_changes -> { post_record.reload.status }, from: "published", to: "draft" do
      patch unpublish_admin_post_path(post_record)
    end

    assert_redirected_to admin_post_path(post_record)
    assert_equal "Post was successfully unpublished.", flash[:success]
  end

  test "unpublishes a post and stops its pending emails" do
    sign_in_as(@author)
    post_record = posts(:pending_email)

    assert_changes -> { post_record.reload.status }, from: "published", to: "draft" do
      assert_changes -> { post_record.reload.email_status }, from: "pending", to: "not_started" do
        patch unpublish_admin_post_path(post_record)
      end
    end

    assert_redirected_to admin_post_path(post_record)
    assert_equal "Post was successfully unpublished. Post emails were successfully stopped.", flash[:success]
  end

  test "shows unchanged message when status is unchanged" do
    sign_in_as(@author)
    published_post = posts(:published)
    draft_post = posts(:draft)

    assert_no_changes -> { published_post.reload.status } do
      patch publish_admin_post_path(published_post)
    end

    assert_redirected_to admin_post_path(published_post)
    assert_equal "Post status was unchanged.", flash[:success]

    assert_no_changes -> { draft_post.reload.status } do
      patch unpublish_admin_post_path(draft_post)
    end

    assert_redirected_to admin_post_path(draft_post)
    assert_equal "Post status was unchanged.", flash[:success]
  end

  test "re-renders edit when publish fails validation" do
    sign_in_as(@author)
    post_record = Post.create!(title: "No Content To Publish", slug: "no-content-to-publish", status: "draft")

    assert_no_changes -> { post_record.reload.status } do
      patch publish_admin_post_path(post_record)
    end

    assert_response :unprocessable_entity
    assert_select "h1", "Edit Post"
    assert_select ".admin-form-errors"
    assert_equal "Content can't be blank", flash[:alert]
  end
end
