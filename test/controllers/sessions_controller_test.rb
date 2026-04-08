require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  setup { @author = Author.take }

  test "new" do
    get new_session_path
    assert_response :success

    assert_select "h1", "Sign in"
    assert_select "form[action=?][method=?]", session_path, "post" do
      assert_select "fieldset.admin-fieldset"
      assert_select "div.admin-form-row input[type=?][name=?][required]", "email", "email_address"
      assert_select "div.admin-form-row input[type=?][name=?][required]", "password", "password"
      assert_select ".form-actions button", text: "Sign in"
      assert_select ".form-actions a[href=?]", new_password_path, text: "Forgot password?"
    end
  end

  test "create with valid credentials" do
    post session_path, params: { email_address: @author.email_address, password: "password" }

    assert_redirected_to root_path
    assert cookies[:session_id]
  end

  test "create with invalid credentials" do
    post session_path, params: { email_address: @author.email_address, password: "wrong" }

    assert_redirected_to new_session_path
    assert_nil cookies[:session_id]
  end

  test "destroy" do
    sign_in_as(Author.take)

    delete session_path

    assert_redirected_to new_session_path
    assert_empty cookies[:session_id]
  end
end
