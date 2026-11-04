require "test_helper"

class SetupGateTest < ActionDispatch::IntegrationTest
  test "html requests render setup page when setup is incomplete" do
    Blog.delete_all

    get root_url

    assert_response :service_unavailable
    assert_select "h1", "there's nothing here yet"
    assert_select "link[rel='stylesheet'][href='#{ApplicationController.helpers.stylesheet_path("themes/terminal")}']"
  end

  test "non-html requests return service unavailable when setup is incomplete" do
    Blog.delete_all

    get feed_url(format: :atom)

    assert_response :service_unavailable
    assert_equal "There's nothing here yet.", response.body
  end
end
