require "thread"
require_relative "tdjson"

module GrubY
  module TDLib
    class ClientManager
      attr_reader :tdjson

      def initialize(lib_path: nil, verbosity: 1)
        @tdjson = TdJson.new(lib_path: lib_path, verbosity: verbosity)
        @clients = {}
        @mutex = Mutex.new
      end

      def add_client(client)
        key = client.native_client_key
        @mutex.synchronize { @clients[key] = client }
        client
      end

      def remove_client(client)
        key = client.native_client_key
        @mutex.synchronize { @clients.delete(key) }
      end

      def each_client(&block)
        snapshot = @mutex.synchronize { @clients.values.dup }
        snapshot.each(&block)
      end

      def close
        each_client(&:stop)
        true
      end
    end
  end
end
