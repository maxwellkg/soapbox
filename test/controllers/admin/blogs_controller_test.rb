require "test_helper"

class Admin::BlogsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @author = authors(:one)
    @blog = blogs(:instance)
  end

  test "redirects unauthenticated access across blog admin routes" do
    get admin_blog_path
    assert_redirected_to new_session_path

    get edit_admin_blog_path
    assert_redirected_to new_session_path

    patch admin_blog_path, params: { blog: { title: "Updated" } }
    assert_redirected_to new_session_path
  end

  test "show displays blog details" do
    sign_in_as(@author)

    get admin_blog_path

    assert_response :success
    assert_select "h1", @blog.title
    assert_select "p", text: /Subtitle:\s+#{Regexp.escape(@blog.subtitle)}/
    assert_select "a[href='#{edit_admin_blog_path}']", text: "edit blog"
  end

  test "edit renders a form" do
    sign_in_as(@author)

    get edit_admin_blog_path

    assert_response :success
    assert_select "h1", "Edit Blog"
    assert_select "form" do
      assert_select "input[type=?][name=?][value=?]", "hidden", "_method", "patch"
    end
    assert_select "input[name='blog[title]'][value=?]", @blog.title
    assert_select "input[name='blog[subtitle]'][value=?]", @blog.subtitle
  end

  test "update changes blog fields" do
    sign_in_as(@author)

    patch admin_blog_path, params: {
      blog: {
        title: "New Soapbox Title",
        subtitle: "Dispatches from the terminal",
        description: "<div>Welcome to the new description.</div>"
      }
    }

    assert_redirected_to admin_blog_path
    assert_equal "Blog was successfully updated", flash[:success]
    assert_equal "New Soapbox Title", @blog.reload.title
    assert_equal "Dispatches from the terminal", @blog.subtitle
    assert_includes @blog.description.body.to_s, "Welcome to the new description."
  end

  test "update re-renders when invalid" do
    sign_in_as(@author)

    assert_no_changes -> { @blog.reload.title } do
      patch admin_blog_path, params: {
        blog: {
          title: ""
        }
      }
    end

    assert_response :success
    assert_equal "Something went wrong", flash[:error]
    assert_select "h1", "Edit Blog"
    assert_select ".admin-form-errors"
  end
end
