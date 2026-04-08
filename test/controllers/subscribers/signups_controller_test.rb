require "test_helper"

class Subscribers::SignupsControllerTest < ActionDispatch::IntegrationTest
  test "create signs up a new subscriber" do
    email_address = "new.subscriber@example.com"

    assert_difference [ -> { Subscriber.count }, -> { Subscription.active.count } ], 1 do
      post signups_url(format: :turbo_stream), params: {
        subscriber: {
          email_address:
        }
      }

      assert_response :success
      assert_equal "#{email_address} is now subscribed!", flash[:success]
      assert_select "turbo-stream[action='update'][target='flashes']"
      assert_select "turbo-stream[action='update'][target='flashes'] template .flash-message", /is now subscribed/
      assert_select "turbo-stream[action='update'][target='flashes'] template turbo-frame", count: 0
    end
  end

  test "create is idempotent for an active subscriber" do
    subscriber = subscribers(:reader_one)

    assert_no_difference [ -> { Subscriber.count }, -> { Subscription.count } ] do
      post signups_url(format: :turbo_stream), params: {
        subscriber: {
          email_address: subscriber.email_address
        }
      }

      assert_response :success
      assert_equal "#{subscriber.email_address} is now subscribed!", flash[:success]
    end
  end

  test "create activates an inactive subscriber" do
    subscriber = subscribers(:reader_without_subscription)

    assert_changes -> { subscriber.reload.active? }, from: false, to: true do
      assert_difference -> { Subscription.active.count }, 1 do
        post signups_url(format: :turbo_stream), params: {
          subscriber: {
            email_address: subscriber.email_address
          }
        }

        assert_response :success
        assert_equal "#{subscriber.email_address} is now subscribed!", flash[:success]
      end
    end
  end

  test "create re-renders form for invalid email address" do
    assert_no_difference [ -> { Subscriber.count }, -> { Subscription.count } ] do
      post signups_url(format: :turbo_stream), params: {
        subscriber: {
          email_address: "not-an-email"
        }
      }

      assert_response :unprocessable_entity
      assert_equal "Sorry, something went wrong", flash[:alert]
      assert_select "turbo-stream[action='update'][target='flashes']"
      assert_select "turbo-stream[action='update'][target='flashes'] template .flash-message", /something went wrong/
      assert_select "turbo-stream[action='update'][target='flashes'] template turbo-frame", count: 0
      assert_select "turbo-stream[action='replace'][target='signup-form'] template div#signup-errors[role='alert']"
      assert_select "turbo-stream[action='replace'][target='signup-form'] template input[name='subscriber[email_address]'][aria-describedby='signup-errors']"
    end
  end
end
