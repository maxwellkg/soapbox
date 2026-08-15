require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  setup { @author = Author.take }

  test "new" do
    get new_password_path
    assert_response :success

    assert_select "h1", "Forgot your password?"
    assert_select "form[action=?][method=?]", passwords_path, "post" do
      assert_select "fieldset.admin-fieldset"
      assert_select "div.admin-form-row input[type=?][name=?][required]", "email", "email_address"
      assert_select ".form-actions button", text: "email reset instructions"
      assert_select ".form-actions a[href=?]", new_session_path, text: "back to sign in"
    end
  end

  test "create" do
    post passwords_path, params: { email_address: @author.email_address }
    assert_enqueued_email_with PasswordsMailer, :reset, args: [ @author ]
    assert_redirected_to new_session_path

    follow_redirect!
    assert_notice "reset instructions sent"
  end

  test "create for an unknown author redirects but sends no mail" do
    post passwords_path, params: { email_address: "missing-author@example.com" }
    assert_enqueued_emails 0
    assert_redirected_to new_session_path

    follow_redirect!
    assert_notice "reset instructions sent"
  end

  test "edit" do
    get edit_password_path(@author.password_reset_token)
    assert_response :success

    assert_select "h1", "Update your password"
    assert_select "form" do
      assert_select "input[type=?][name=?][value=?]", "hidden", "_method", "put"
      assert_select "fieldset.admin-fieldset"
      assert_select "div.admin-form-row input[type=?][name=?][required]", "password", "password"
      assert_select "div.admin-form-row input[type=?][name=?][required]", "password", "password_confirmation"
      assert_select ".form-actions button", text: "save"
    end
  end

  test "edit with invalid password reset token" do
    get edit_password_path("invalid token")
    assert_redirected_to new_password_path

    follow_redirect!
    assert_notice "reset link is invalid"
  end

  test "update" do
    assert_changes -> { @author.reload.password_digest } do
      put password_path(@author.password_reset_token), params: { password: "new", password_confirmation: "new" }
      assert_redirected_to new_session_path
    end

    follow_redirect!
    assert_notice "Password has been reset"
  end

  test "update with non matching passwords" do
    token = @author.password_reset_token
    assert_no_changes -> { @author.reload.password_digest } do
      put password_path(token), params: { password: "no", password_confirmation: "match" }
      assert_redirected_to edit_password_path(token)
    end

    follow_redirect!
    assert_notice "Passwords did not match"
  end

  private
    def assert_notice(text)
      assert_select "div", /#{text}/
    end
end
