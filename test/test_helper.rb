ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "test_helpers/flash_test_helper"
require_relative "test_helpers/session_test_helper"

module ActiveSupport
  class TestCase
    include Rails.application.routes.url_helpers
    include ActionMailer::TestHelper
    include ActionDispatch::TestProcess::FixtureFile

    parallelize(workers: :number_of_processors)

    fixtures :all

    def temporarily_redefine_method(klass, method_name, replacement_proc)
      original_method = klass.instance_method(method_name)

      klass.define_method(method_name) do |*args, &block|
        instance_exec(*args, &replacement_proc)
      end

      yield
    ensure
      klass.define_method(method_name, original_method)
    end

    def attach_site_image(record)
      file_fixture("site_image.png").open do |file|
        record.site_image.attach(io: file, filename: "site_image.png", content_type: "image/png")
      end
    end

    def after_teardown
      Rails.cache.clear
      super
    end
  end
end

class ActionDispatch::IntegrationTest
  include FlashTestHelper
end
