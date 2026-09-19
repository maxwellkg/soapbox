require "test_helper"

class Admin::DashboardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @author = authors(:instance)
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
    assert_select "section.page-actions a", count: 5
    assert_select "a[href='#{root_path}']", text: "back to blog"
    assert_select "a[href='#{admin_author_path}']", text: "manage account"
    assert_select "a[href='#{admin_blog_path}']", text: "manage blog"
    assert_select "a[href='#{admin_posts_path}']", text: "manage posts"
    assert_select "a[href='#{admin_subscribers_path}']", text: "manage subscribers"
    assert_select "p", text: /Welcome,\s+#{Regexp.escape(@author.full_name)}/
  end
end
