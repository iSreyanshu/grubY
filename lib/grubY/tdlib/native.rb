require "ffi"

module GrubY
  module TDLib
    module Native
      extend FFI::Library

      class LibraryNotFoundError < StandardError; end

      class << self
        def load!(path = nil)
          return if @loaded

          ffi_lib(resolve_library_path(path))
          attach_function :td_json_client_create, [], :pointer
          attach_function :td_json_client_send, [:pointer, :string], :void
          attach_function :td_json_client_receive, [:pointer, :double], :string
          attach_function :td_json_client_execute, [:pointer, :string], :string
          attach_function :td_json_client_destroy, [:pointer], :void
          attach_function :td_set_log_verbosity_level, [:int], :void
          @loaded = true
        end

        private

        def resolve_library_path(custom_path)
          return custom_path if custom_path && File.exist?(custom_path)

          env_path = ENV["TDJSON_PATH"]
          return env_path if env_path && File.exist?(env_path)

          candidates = default_candidates
          found = candidates.find { |path| File.exist?(path) }
          return found if found

          raise LibraryNotFoundError,
            "TDLib (tdjson) not found. Set TDJSON_PATH or pass tdjson_path."
        end

        def default_candidates
          if Gem.win_platform?
            [
              "tdjson.dll",
              "C:/tdlib/bin/tdjson.dll",
              "C:/Program Files/TDLib/bin/tdjson.dll"
            ]
          elsif RUBY_PLATFORM.include?("darwin")
            [
              "libtdjson.dylib",
              "/usr/local/lib/libtdjson.dylib",
              "/opt/homebrew/lib/libtdjson.dylib"
            ]
          else
            [
              "libtdjson.so",
              "/usr/lib/libtdjson.so",
              "/usr/local/lib/libtdjson.so"
            ]
          end
        end
      end
    end
  end
end
