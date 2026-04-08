require "test_helper"
require "rake"

class SiteTaskTest < ActiveSupport::TestCase
  setup do
    Rails.application.load_tasks if Rake::Task.tasks.empty?
    Rake::Task["site:setup"].reenable
  end

  test "site:setup completes when setup succeeds" do
    temporarily_redefine_method(SiteSetup.singleton_class, :run, -> { true }) do
      assert_nothing_raised { Rake::Task["site:setup"].invoke }
    end
  end

  test "site:setup aborts when setup fails" do
    temporarily_redefine_method(SiteSetup.singleton_class, :run, -> { false }) do
      error = assert_raises(SystemExit) { Rake::Task["site:setup"].invoke }

      assert_equal 1, error.status
    end
  end
end
