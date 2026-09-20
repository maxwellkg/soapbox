require "test_helper"

class Searchable::ControllerTest < ActiveSupport::TestCase
  class DummyController
    def self.helper_method(*)
    end

    include Searchable::Controller

    attr_accessor :params

    public :search_given?, :searching?, :search_term, :search_params
  end

  test "extracts search term" do
    controller = DummyController.new
    controller.params = ActionController::Parameters.new(search: "hello", status: "active")

    assert_equal "hello", controller.search_term
    assert controller.search_given?
    assert controller.searching?
    assert_equal({ "search" => "hello" }, controller.search_params.to_h)
  end

  test "blank search term is not considered given" do
    controller = DummyController.new
    controller.params = ActionController::Parameters.new(search: "")

    assert_nil controller.search_term
    assert_not controller.search_given?
    assert_not controller.searching?
  end
end
