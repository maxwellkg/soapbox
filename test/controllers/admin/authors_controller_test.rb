require "test_helper"

class Admin::AuthorsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @author = authors(:one)
  end

  test "redirects unauthenticated access across author admin routes" do
    get admin_author_path
    assert_redirected_to new_session_path

    get edit_admin_author_path
    assert_redirected_to new_session_path

    patch admin_author_path, params: { author: { first_name: "Updated" } }
    assert_redirected_to new_session_path
  end

  test "show displays author details" do
    sign_in_as(@author)

    get admin_author_path

    assert_response :success
    assert_select "h1", @author.full_name
    assert_select "p", text: /First name:\s+#{Regexp.escape(@author.first_name)}/
    assert_select "p", text: /Last name:\s+#{Regexp.escape(@author.last_name)}/
    assert_select "p", text: /Email address:\s+#{Regexp.escape(@author.email_address)}/
    assert_select "a[href='#{edit_admin_author_path}']", text: "edit account"
  end

  test "edit renders a form" do
    sign_in_as(@author)

    get edit_admin_author_path

    assert_response :success
    assert_select "h1", "Edit Account"
    assert_select "form" do
      assert_select "input[type=?][name=?][value=?]", "hidden", "_method", "patch"
    end
    assert_select "input[name='author[first_name]'][value=?]", @author.first_name
    assert_select "input[name='author[last_name]'][value=?]", @author.last_name
    assert_select "input[name='author[email_address]'][value=?]", @author.email_address
  end

  test "update changes author fields" do
    sign_in_as(@author)

    patch admin_author_path, params: {
      author: {
        first_name: "Max",
        last_name: "Gove",
        email_address: "max@example.com"
      }
    }

    assert_redirected_to admin_author_path
    assert_equal "Account was successfully updated", flash[:success]
    assert_equal "Max", @author.reload.first_name
    assert_equal "Gove", @author.last_name
    assert_equal "max@example.com", @author.email_address
  end

  test "update re-renders when invalid" do
    sign_in_as(@author)

    assert_no_changes -> { [ @author.reload.first_name, @author.last_name, @author.email_address ] } do
      patch admin_author_path, params: {
        author: {
          first_name: "",
          last_name: "",
          email_address: "not-an-email"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_equal "Something went wrong", flash[:error]
    assert_select "h1", "Edit Account"
    assert_select ".admin-form-errors"
  end
end
