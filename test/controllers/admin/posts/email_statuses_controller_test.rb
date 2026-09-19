require "test_helper"

class Admin::Posts::EmailStatusesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @author = authors(:instance)
  end

  test "redirects unauthenticated start and stop" do
    post_record = posts(:published)

    patch start_emails_admin_post_path(post_record)
    assert_redirected_to new_session_path

    patch stop_emails_admin_post_path(post_record)
    assert_redirected_to new_session_path
  end

  test "starts post emails" do
    sign_in_as(@author)
    post_record = posts(:published)

    assert_changes -> { post_record.reload.email_status }, from: "not_started", to: "pending" do
      patch start_emails_admin_post_path(post_record)
    end

    assert_redirected_to admin_post_path(post_record)
    assert_equal "Post emails were successfully started.", flash[:success]
  end

  test "stops post emails" do
    sign_in_as(@author)
    post_record = posts(:pending_email)

    assert_changes -> { post_record.reload.email_status }, from: "pending", to: "not_started" do
      patch stop_emails_admin_post_path(post_record)
    end

    assert_redirected_to admin_post_path(post_record)
    assert_equal "Post emails were successfully stopped.", flash[:success]
  end

  test "shows unchanged message when email status is unchanged" do
    sign_in_as(@author)
    post_record = posts(:pending_email)

    assert_no_changes -> { post_record.reload.email_status } do
      patch start_emails_admin_post_path(post_record)
    end

    assert_redirected_to admin_post_path(post_record)
    assert_equal "Post email status was unchanged.", flash[:success]
  end

  test "re-renders edit when command fails" do
    sign_in_as(@author)
    post_record = posts(:draft)

    assert_no_changes -> { post_record.reload.email_status } do
      patch start_emails_admin_post_path(post_record)
    end

    assert_response :unprocessable_entity
    assert_select "h1", "Edit Post"
    assert_includes flash[:alert], "cannot be moved to pending unless published"
  end
end
