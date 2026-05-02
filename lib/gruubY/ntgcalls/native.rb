require "ffi"

module GrubY
  module NTgCalls
    module Native
      extend FFI::Library

      class LibraryNotFoundError < StandardError; end

      callback :ntg_async_callback, [:pointer], :void

      class NtgAsyncStruct < FFI::Struct
        layout :userData, :pointer,
               :errorCode, :pointer,
               :errorMessage, :pointer,
               :promise, :ntg_async_callback
      end

      class NtgAudioDescriptionStruct < FFI::Struct
        layout :mediaSource, :int,
               :input, :string,
               :sampleRate, :uint32,
               :channelCount, :uint8,
               :keepOpen, :bool
      end

      class NtgMediaDescriptionStruct < FFI::Struct
        layout :microphone, :pointer,
               :speaker, :pointer,
               :camera, :pointer,
               :screen, :pointer
      end

      class << self
        def load!(path = nil)
          return if @loaded

          ffi_lib(resolve_library_path(path))
          attach_function :ntg_init, [], :uintptr_t
          attach_function :ntg_destroy, [:uintptr_t], :int
          attach_function :ntg_get_version, [:pointer], :int
          attach_function :ntg_create, [:uintptr_t, :int64, :pointer, NtgAsyncStruct.by_value], :int
          attach_function :ntg_connect, [:uintptr_t, :int64, :string, :bool, NtgAsyncStruct.by_value], :int
          attach_function :ntg_set_stream_sources, [:uintptr_t, :int64, :int, NtgMediaDescriptionStruct.by_value, NtgAsyncStruct.by_value], :int
          attach_function :ntg_pause, [:uintptr_t, :int64, NtgAsyncStruct.by_value], :int
          attach_function :ntg_resume, [:uintptr_t, :int64, NtgAsyncStruct.by_value], :int
          attach_function :ntg_mute, [:uintptr_t, :int64, NtgAsyncStruct.by_value], :int
          attach_function :ntg_unmute, [:uintptr_t, :int64, NtgAsyncStruct.by_value], :int
          attach_function :ntg_stop, [:uintptr_t, :int64, NtgAsyncStruct.by_value], :int
          attach_function :ntg_time, [:uintptr_t, :int64, :int, :pointer, NtgAsyncStruct.by_value], :int
          attach_function :ntg_cpu_usage, [:uintptr_t, :pointer, NtgAsyncStruct.by_value], :int
          @loaded = true
        end

        private

        def resolve_library_path(custom_path)
          return custom_path if custom_path && File.exist?(custom_path)

          env_path = ENV["NTGCALLS_PATH"]
          return env_path if env_path && File.exist?(env_path)

          found = default_candidates.find { |path| File.exist?(path) }
          return found if found

          raise LibraryNotFoundError,
            "NTgCalls shared library not found. Set NTGCALLS_PATH or pass lib_path."
        end

        def default_candidates
          if Gem.win_platform?
            [
              "ntgcalls.dll",
              "vendor/ntgcalls/windows/ntgcalls.dll",
              "vendor/ntgcalls/ntgcalls.dll",
              "C:/ntgcalls/bin/ntgcalls.dll"
            ]
          elsif RUBY_PLATFORM.include?("darwin")
            [
              "libntgcalls.dylib",
              "vendor/ntgcalls/macos/libntgcalls.dylib",
              "vendor/ntgcalls/darwin/libntgcalls.dylib",
              "vendor/ntgcalls/libntgcalls.dylib",
              "/usr/local/lib/libntgcalls.dylib",
              "/opt/homebrew/lib/libntgcalls.dylib"
            ]
          else
            [
              "libntgcalls.so",
              "vendor/ntgcalls/linux/libntgcalls.so",
              "vendor/ntgcalls/libntgcalls.so",
              "/usr/lib/libntgcalls.so",
              "/usr/local/lib/libntgcalls.so"
            ]
          end
        end
      end
    end
  end
end
