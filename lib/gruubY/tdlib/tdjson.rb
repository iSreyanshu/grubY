require "json"
require_relative "native"

module GrubY
  module TDLib
    class TdJson
      attr_reader :version

      def initialize(lib_path: nil, verbosity: 1)
        Native.load!(lib_path)
        Native.td_set_log_verbosity_level(verbosity.to_i)
        @version = fetch_version
      end

      def create_client_id
        Native.td_json_client_create
      end

      def send(client_id, request)
        Native.td_json_client_send(client_id, JSON.generate(request))
      end

      def receive(client_id, timeout:)
        raw = Native.td_json_client_receive(client_id, timeout.to_f)
        raw ? JSON.parse(raw) : nil
      end

      def execute(client_id, request)
        raw = Native.td_json_client_execute(client_id, JSON.generate(request))
        raw ? JSON.parse(raw) : nil
      end

      def destroy(client_id)
        Native.td_json_client_destroy(client_id)
      end

      private

      def fetch_version
        temp = create_client_id
        response = execute(temp, { "@type" => "getOption", "name" => "version" })
        destroy(temp)
        response&.dig("value", "value")
      rescue StandardError
        nil
      end
    end
  end
end
