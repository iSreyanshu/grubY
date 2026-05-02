require "base64"
require "json"
require "securerandom"

module GrubY
  module TDLib
    module UserSession
      module_function

      VERSION = 1

      def encode(
        api_id:,
        api_hash:,
        database_directory:,
        files_directory:,
        database_encryption_key: "",
        session_name: nil
      )
        payload = {
          "v" => VERSION,
          "api_id" => api_id.to_i,
          "api_hash" => api_hash.to_s,
          "database_directory" => database_directory.to_s,
          "files_directory" => files_directory.to_s,
          "database_encryption_key" => database_encryption_key.to_s,
          "session_name" => session_name.to_s
        }
        Base64.urlsafe_encode64(payload.to_json)
      end

      def decode(session_string)
        raise ArgumentError, "session_string is empty" if session_string.to_s.strip.empty?

        payload = JSON.parse(Base64.urlsafe_decode64(session_string.to_s.strip))
        unless payload.is_a?(Hash) && payload["v"].to_i == VERSION
          raise ArgumentError, "invalid session string version"
        end

        payload
      rescue ArgumentError, JSON::ParserError => e
        raise ArgumentError, "invalid session string: #{e.message}"
      end

      def build(session_name: "default", root: "storage/tdlib-sessions")
        normalized = session_name.to_s.strip
        normalized = "default" if normalized.empty?

        {
          session_name: normalized,
          database_directory: File.join(root, normalized, "db"),
          files_directory: File.join(root, normalized, "files"),
          database_encryption_key: SecureRandom.hex(24)
        }
      end

      def client_kwargs(session_string)
        payload = decode(session_string)
        {
          api_id: payload.fetch("api_id").to_i,
          api_hash: payload.fetch("api_hash").to_s,
          database_directory: payload.fetch("database_directory").to_s,
          files_directory: payload.fetch("files_directory").to_s,
          database_encryption_key: payload.fetch("database_encryption_key").to_s
        }
      end
    end
  end
end
