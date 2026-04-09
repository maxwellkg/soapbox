require "test_helper"

class Admin::SubscribersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @author = authors(:one)
  end

  test "redirects unauthenticated access across subscriber admin routes" do
    subscriber = subscribers(:reader_one)

    get admin_subscribers_path
    assert_redirected_to new_session_path

    get admin_subscriber_path(subscriber)
    assert_redirected_to new_session_path

    get new_admin_subscriber_path
    assert_redirected_to new_session_path

    get edit_admin_subscriber_path(subscriber)
    assert_redirected_to new_session_path

    post admin_subscribers_path, params: { subscriber: { email_address: "new@example.com" } }
    assert_redirected_to new_session_path

    patch admin_subscriber_path(subscriber), params: { subscriber: { email_address: "updated@example.com" } }
    assert_redirected_to new_session_path
  end

  test "index lists subscribers" do
    sign_in_as(@author)

    get admin_subscribers_path

    assert_response :success
    assert_select "h1", "Subscribers"
    assert_select "h2", count: 20

    Subscriber.order(updated_at: :desc).limit(20).each do |subscriber|
      assert_select "h2", text: subscriber.email_address
    end
  end

  test "index searches subscribers" do
    sign_in_as(@author)

    get admin_subscribers_path, params: { search: "reader.one" }

    assert_response :success
    assert_select "h2", count: 1
    assert_select "h2", text: subscribers(:reader_one).email_address
    assert_select "p", text: "1 matching subscriber"

    get admin_subscribers_path, params: { search: "no-such-subscriber" }

    assert_response :success
    assert_select "h2", count: 0
    assert_select "p", text: "0 matching subscribers"
  end

  test "index filters subscribers by status" do
    sign_in_as(@author)

    get admin_subscribers_path, params: { status: "active" }
    assert_response :success
    assert_select "h2", count: 4

    get admin_subscribers_path, params: { status: "inactive" }
    assert_response :success
    assert_select "h2", count: 20

    get admin_subscribers_path, params: { status: "" }
    assert_response :success
    assert_select "h2", count: 20

    get admin_subscribers_path, params: { status: "foobar" }
    assert_response :success
    assert_select "h2", count: 0
  end

  test "index combines search and status filter" do
    sign_in_as(@author)

    get admin_subscribers_path, params: { search: "reader", status: "inactive" }

    assert_response :success
    assert_select "h2", count: 1
    assert_select "h2", text: subscribers(:reader_without_subscription).email_address

    get admin_subscribers_path, params: { search: "reader", status: "active" }

    assert_response :success
    assert_select "h2", count: 4
  end

  test "show displays the subscriber" do
    sign_in_as(@author)
    subscriber = subscribers(:reader_three)

    get admin_subscriber_path(subscriber)

    assert_response :success
    assert_select "h1", subscriber.email_address
    assert_select "p", text: /Status:\s+Active/
  end

  test "new renders a form" do
    sign_in_as(@author)

    get new_admin_subscriber_path

    assert_response :success
    assert_select "h1", "New Subscriber"
    assert_select "form[action=?][method=?]", admin_subscribers_path, "post"
  end

  test "edit renders a form" do
    sign_in_as(@author)
    subscriber = subscribers(:reader_two)

    get edit_admin_subscriber_path(subscriber)

    assert_response :success
    assert_select "h1", "Edit Subscriber"
    assert_select "form[action=?]", admin_subscriber_path(subscriber) do
      assert_select "input[type=?][name=?][value=?]", "hidden", "_method", "patch"
    end
  end

  test "create creates and activates a subscriber" do
    sign_in_as(@author)

    assert_difference [ -> { Subscriber.count }, -> { Subscription.active.count } ], 1 do
      post admin_subscribers_path, params: {
        subscriber: {
          email_address: "new.admin.subscriber@example.com"
        }
      }
    end

    created = Subscriber.order(:id).last
    assert created.active?
    assert_redirected_to admin_subscriber_path(created)
    assert_equal "Subscriber was successfully created.", flash[:success]
  end

  test "create re-renders when invalid" do
    sign_in_as(@author)

    assert_no_difference [ -> { Subscriber.count }, -> { Subscription.count } ] do
      post admin_subscribers_path, params: {
        subscriber: {
          email_address: "not-an-email"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "h1", "New Subscriber"
    assert_select ".admin-form-errors"
    assert_equal "Sorry, something went wrong.", flash[:alert]
  end

  test "update changes the subscriber" do
    sign_in_as(@author)
    subscriber = subscribers(:reader_two)

    assert_changes -> { subscriber.reload.email_address }, to: "reader.two.updated@example.com" do
      patch admin_subscriber_path(subscriber), params: {
        subscriber: {
          email_address: "reader.two.updated@example.com"
        }
      }
    end

    assert_redirected_to admin_subscriber_path(subscriber)
    assert_equal "Subscriber was successfully updated.", flash[:success]
  end

  test "update re-renders when invalid" do
    sign_in_as(@author)
    subscriber = subscribers(:reader_two)

    assert_no_changes -> { subscriber.reload.email_address } do
      patch admin_subscriber_path(subscriber), params: {
        subscriber: {
          email_address: ""
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "h1", "Edit Subscriber"
    assert_select ".admin-form-errors"
    assert_equal "Sorry, something went wrong.", flash[:alert]
  end

  test "index paginates subscribers and keeps filters in links" do
    sign_in_as(@author)

    get admin_subscribers_path, params: { search: "pagination.subscriber", status: "inactive" }

    assert_response :success
    assert_select "article.admin-card", count: 20
    assert_select "p", text: "21 matching subscribers"
    assert_select ".pagination-page", text: "Page 1 of 2"
    assert_select "span.pagination-link-disabled", text: "Previous"
    assert_select "a.pagination-link[href*='search=pagination.subscriber'][href*='status=inactive'][href*='page=2']", text: "Next"

    get admin_subscribers_path, params: { search: "pagination.subscriber", status: "inactive", page: 2 }

    assert_response :success
    assert_select "article.admin-card", count: 1
    assert_select ".pagination-page", text: "Page 2 of 2"
    assert_select "a.pagination-link[href*='search=pagination.subscriber'][href*='status=inactive'][href*='page=1']", text: "Previous"
    assert_select "span.pagination-link-disabled", text: "Next"
  end
end
