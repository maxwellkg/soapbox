require "test_helper"

class Admin::DashboardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @author = authors(:one)
  end

  test "redirects unauthenticated dashboard access" do
    get admin_root_path

    assert_redirected_to new_session_path
  end

  test "dashboard renders management links" do
    sign_in_as(@author)

    get admin_root_path

    assert_response :success
    assert_select "h1", "Admin"
    assert_select "section.page-actions a", count: 4
    assert_select "a[href='#{root_path}']", text: "Back to blog"
    assert_select "a[href='#{admin_blog_path}']", text: "Manage blog"
    assert_select "a[href='#{admin_posts_path}']", text: "Manage posts"
    assert_select "a[href='#{admin_subscribers_path}']", text: "Manage subscribers"
  end
end
