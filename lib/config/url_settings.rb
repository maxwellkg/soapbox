require "uri"

module Config
  class URLSettings
    def initialize(env: ENV)
      @env = env
    end

    def default_url_options
      {
        protocol: parsed_app_url.scheme,
        host: parsed_app_url.host,
        port: port_for_url_options
      }.compact_blank
    end

    def force_ssl?
      parsed_app_url.scheme == "https"
    end

    private
      attr_reader :env

      def parsed_app_url
        @parsed_app_url ||= URI.parse(app_url)
      end

      def app_url
        @app_url ||= retrieve_environment_variable("APP_URL")
      end

      def port_for_url_options
        parsed_app_url.port if parsed_app_url.port.present? && !default_port?
      end

      def default_port?
        parsed_app_url.port == parsed_app_url.default_port
      end

      def retrieve_environment_variable(key)
        env[key]&.strip.presence || raise("#{key} is required in production")
      end
  end
end
