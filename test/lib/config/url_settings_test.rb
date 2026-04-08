require "test_helper"

class Config::URLSettingsTest < ActiveSupport::TestCase
  test "default_url_options raises when APP_URL is missing" do
    settings = Config::URLSettings.new(env: {})

    error = assert_raises(RuntimeError) { settings.default_url_options }

    assert_equal "APP_URL is required in production", error.message
  end

  test "default_url_options raises when APP_URL is blank" do
    settings = Config::URLSettings.new(env: { "APP_URL" => "  " })

    error = assert_raises(RuntimeError) { settings.default_url_options }

    assert_equal "APP_URL is required in production", error.message
  end

  test "default_url_options includes protocol and host for https" do
    settings = Config::URLSettings.new(env: { "APP_URL" => "https://blog.example.com" })

    assert_equal({ protocol: "https", host: "blog.example.com" }, settings.default_url_options)
  end

  test "default_url_options includes non-default port" do
    settings = Config::URLSettings.new(env: { "APP_URL" => "http://localhost:3000" })

    assert_equal({ protocol: "http", host: "localhost", port: 3000 }, settings.default_url_options)
  end

  test "default_url_options omits default port" do
    settings = Config::URLSettings.new(env: { "APP_URL" => "https://blog.example.com:443" })

    assert_equal({ protocol: "https", host: "blog.example.com" }, settings.default_url_options)
  end

  test "force_ssl? is true for https" do
    settings = Config::URLSettings.new(env: { "APP_URL" => "https://blog.example.com" })

    assert settings.force_ssl?
  end

  test "force_ssl? is false for http" do
    settings = Config::URLSettings.new(env: { "APP_URL" => "http://blog.example.com" })

    assert_not settings.force_ssl?
  end
end
