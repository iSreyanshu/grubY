require "timeout"
require "thread"
require_relative "ntgcalls/native"

module GrubY
  module NTgCalls
    class Error < StandardError; end

    module StreamMode
      CAPTURE = 0
      PLAYBACK = 1
    end

    module MediaSource
      FILE = 1 << 0
      SHELL = 1 << 1
      FFMPEG = 1 << 2
      DEVICE = 1 << 3
      DESKTOP = 1 << 4
      EXTERNAL = 1 << 5
    end

    class Client
      DEFAULT_TIMEOUT = 20
      attr_reader :handle

      def initialize(lib_path: nil)
        Native.load!(lib_path)
        @handle = Native.ntg_init
        raise Error, "ntgcalls init failed" if @handle.nil? || @handle.zero?
      end

      def self.version(lib_path: nil)
        Native.load!(lib_path)
        version_ptr = FFI::MemoryPointer.new(:pointer)
        code = Native.ntg_get_version(version_ptr)
        raise Error, "ntg_get_version failed with code=#{code}" if code.negative?

        read_c_string_ptr(version_ptr)
      end

      def close
        return if @handle.nil? || @handle.zero?

        code = Native.ntg_destroy(@handle)
        raise Error, "ntg_destroy failed with code=#{code}" if code.negative?

        @handle = nil
      end

      alias stop close

      def create(chat_id:, timeout: DEFAULT_TIMEOUT)
        call_async_string(:ntg_create, [handle!, chat_id.to_i], timeout: timeout)
      end

      def connect(chat_id:, params:, is_presentation: false, timeout: DEFAULT_TIMEOUT)
        call_async(
          :ntg_connect,
          [handle!, chat_id.to_i, params.to_s, !!is_presentation],
          timeout: timeout
        )
      end

      def play(chat_id:, stream:, sample_rate: 48_000, channels: 2, keep_open: false, timeout: DEFAULT_TIMEOUT)
        audio = Native::NtgAudioDescriptionStruct.new
        audio[:mediaSource] = MediaSource::FILE
        audio[:input] = stream.to_s
        audio[:sampleRate] = sample_rate.to_i
        audio[:channelCount] = channels.to_i
        audio[:keepOpen] = !!keep_open

        media = Native::NtgMediaDescriptionStruct.new
        media[:microphone] = audio.to_ptr
        media[:speaker] = FFI::Pointer::NULL
        media[:camera] = FFI::Pointer::NULL
        media[:screen] = FFI::Pointer::NULL

        call_async(
          :ntg_set_stream_sources,
          [handle!, chat_id.to_i, StreamMode::CAPTURE, media],
          timeout: timeout
        )
      end

      def pause(chat_id:, timeout: DEFAULT_TIMEOUT)
        call_async(:ntg_pause, [handle!, chat_id.to_i], timeout: timeout)
      end

      def resume(chat_id:, timeout: DEFAULT_TIMEOUT)
        call_async(:ntg_resume, [handle!, chat_id.to_i], timeout: timeout)
      end

      def mute(chat_id:, timeout: DEFAULT_TIMEOUT)
        call_async(:ntg_mute, [handle!, chat_id.to_i], timeout: timeout)
      end

      def unmute(chat_id:, timeout: DEFAULT_TIMEOUT)
        call_async(:ntg_unmute, [handle!, chat_id.to_i], timeout: timeout)
      end

      def stop_call(chat_id:, timeout: DEFAULT_TIMEOUT)
        call_async(:ntg_stop, [handle!, chat_id.to_i], timeout: timeout)
      end

      def cpu_usage(timeout: DEFAULT_TIMEOUT)
        out = FFI::MemoryPointer.new(:double)
        call_async(:ntg_cpu_usage, [handle!, out], timeout: timeout)
        out.read_double
      end

      def time(chat_id:, mode: StreamMode::CAPTURE, timeout: DEFAULT_TIMEOUT)
        out = FFI::MemoryPointer.new(:int64)
        call_async(:ntg_time, [handle!, chat_id.to_i, mode.to_i, out], timeout: timeout)
        out.read_int64
      end

      private

      def handle!
        raise Error, "ntgcalls client is closed" if @handle.nil? || @handle.zero?

        @handle
      end

      def call_async_string(function_name, args, timeout:)
        out_ptr = FFI::MemoryPointer.new(:pointer)
        call_async(function_name, args + [out_ptr], timeout: timeout)
        self.class.read_c_string_ptr(out_ptr)
      end

      def call_async(function_name, args, timeout:)
        done = Queue.new
        error_code = FFI::MemoryPointer.new(:int)
        error_code.write_int(0)
        error_message = FFI::MemoryPointer.new(:pointer)
        error_message.write_pointer(FFI::Pointer::NULL)

        callback = proc do |_user_data|
          done << true
        end

        future = Native::NtgAsyncStruct.new
        future[:userData] = FFI::Pointer::NULL
        future[:errorCode] = error_code
        future[:errorMessage] = error_message
        future[:promise] = callback

        code = Native.public_send(function_name, *args, future)
        raise_native_error(code, error_message) if code.negative?

        begin
          Timeout.timeout(timeout) { done.pop }
        rescue Timeout::Error
          raise Error, "ntgcalls timeout while waiting for #{function_name}"
        end

        async_code = error_code.read_int
        raise_native_error(async_code, error_message) if async_code.negative?
        true
      end

      def raise_native_error(code, error_message_ptr)
        message_ptr = error_message_ptr.read_pointer
        native_message = message_ptr.null? ? nil : message_ptr.read_string
        suffix = native_message.to_s.empty? ? "" : " (#{native_message})"
        raise Error, "ntgcalls error code=#{code}#{suffix}"
      end

      class << self
        def read_c_string_ptr(pointer_to_pointer)
          ptr = pointer_to_pointer.read_pointer
          return "" if ptr.null?

          ptr.read_string
        end
      end
    end

    class Bridge
      def initialize(*_args, **_kwargs)
        raise Error, "Use GrubY::NTgCalls::Client (pure Ruby based ntgcalls C bindings)."
      end
    end

    class RBtgCalls < Bridge; end
  end
end
