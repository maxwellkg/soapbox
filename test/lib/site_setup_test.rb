require "test_helper"

class SiteSetupTest < ActiveSupport::TestCase
  test "run creates missing singleton records" do
    Author.delete_all
    Blog.delete_all

    result, output = with_stubbed_stdio(<<~INPUT) do
      Ada
      Lovelace
      ada@example.com
      password123
      password123
      The Analytical Engine
      Notes from London
    INPUT
      SiteSetup.run
    end

    assert result
    assert_includes output, "Setup is now complete"
    assert_includes output, "Next step: add your full blog description at /admin/blog/edit"
    assert_equal "Ada", Author.instance.first_name
    assert_equal "Lovelace", Author.instance.last_name
    assert_equal "ada@example.com", Author.instance.email_address
    assert Author.instance.authenticate("password123")
    assert_equal "The Analytical Engine", Blog.instance.title
    assert_equal "Notes from London", Blog.instance.subtitle
  end

  test "run is idempotent when singleton records already exist" do
    Blog.instance.update!(description: "")

    result, output = with_stubbed_stdio("") { SiteSetup.run }

    assert result
    assert_includes output, "Setup is already complete"
    assert_includes output, "Next step: add your full blog description at /admin/blog/edit"
  end

  test "run does not print description guidance when description exists" do
    Blog.instance.update!(description: "Already set")

    result, output = with_stubbed_stdio("") { SiteSetup.run }

    assert result
    assert_includes output, "Setup is already complete"
    assert_not_includes output, "Next step: add your full blog description at /admin/blog/edit"
  end

  test "run fails when input closes before completion" do
    Author.delete_all
    Blog.delete_all

    result, output = with_stubbed_stdio("") { SiteSetup.run }

    assert_not result
    assert_includes output, "Setup canceled: input was closed before completion"
  end

  private
    def with_stubbed_stdio(input)
      original_stdin = $stdin
      original_stdout = $stdout

      fake_stdin = StringIO.new(input)
      fake_stdin.define_singleton_method(:noecho) { |&block| block.call(fake_stdin) }
      fake_stdout = StringIO.new

      $stdin = fake_stdin
      $stdout = fake_stdout

      [ yield, fake_stdout.string ]
    ensure
      $stdin = original_stdin
      $stdout = original_stdout
    end
end
