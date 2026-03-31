ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require_relative "test_helpers/session_test_helper"

module ActiveSupport
  class TestCase
    include Rails.application.routes.url_helpers
    include ActionMailer::TestHelper

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
  end
end
