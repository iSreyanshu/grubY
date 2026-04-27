require "timeout"
require "thread"
require "securerandom"
require_relative "ntgcalls/native"
require_relative "tdlib/client"
require_relative "tdlib/user_session"

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

    class MusicBot
      DEFAULT_AUTH_TIMEOUT = 180

      def initialize(
        td_user_session:,
        tdjson_path: nil,
        ntgcalls_path: nil,
        phone_number: nil,
        td_verbosity: 1
      )
        td_cfg = GrubY::TDLib::UserSession.client_kwargs(td_user_session)
        @td = GrubY::TDLib::Client.new(
          **td_cfg,
          phone_number: phone_number,
          tdjson_path: tdjson_path,
          td_verbosity: td_verbosity,
          workers: 2
        )
        @ntg = Client.new(lib_path: ntgcalls_path)
        @joined_chat_id = nil
        @phone_number = phone_number
        @td.on("updateAuthorizationState") { |update| handle_auth_state(update) }
      end

      def start(timeout: DEFAULT_AUTH_TIMEOUT)
        @td.start
        wait_until_authorized!(timeout: timeout)
        self
      end

      def stop
        @ntg.close
        @td.stop
      end

      def join_and_play(chat:, audio:, invite_hash: "")
        chat_id = resolve_chat_id(chat)
        input_group_call = fetch_input_group_call(chat_id)
        local_offer = @ntg.create(chat_id: chat_id)
        audio_source_id = deterministic_audio_source_id(chat_id)

        join_response = try_join_group_call(
          input_group_call: input_group_call,
          local_offer: local_offer,
          audio_source_id: audio_source_id,
          invite_hash: invite_hash
        )
        remote_params = extract_join_payload(join_response)
        raise Error, "joinGroupCall response did not contain tgcalls params" if remote_params.to_s.empty?

        @ntg.connect(chat_id: chat_id, params: remote_params)
        @ntg.play(chat_id: chat_id, stream: audio)
        @joined_chat_id = chat_id

        {
          chat_id: chat_id,
          offer: local_offer,
          remote_params: remote_params
        }
      end

      def pause
        @ntg.pause(chat_id: joined_chat_id!)
      end

      def resume
        @ntg.resume(chat_id: joined_chat_id!)
      end

      def mute
        @ntg.mute(chat_id: joined_chat_id!)
      end

      def unmute
        @ntg.unmute(chat_id: joined_chat_id!)
      end

      def stop_call
        @ntg.stop_call(chat_id: joined_chat_id!)
      end

      def cpu_usage
        @ntg.cpu_usage
      end

      def time
        @ntg.time(chat_id: joined_chat_id!)
      end

      private

      def joined_chat_id!
        raise Error, "no active group call in this bot instance" if @joined_chat_id.nil?

        @joined_chat_id
      end

      def wait_until_authorized!(timeout:)
        deadline = Time.now + timeout
        loop do
          return true if @td.authorized?
          raise Error, "TDLib authorization timeout" if Time.now > deadline
          sleep 0.25
        end
      end

      def handle_auth_state(update)
        state = update.dig("authorization_state", "@type")
        case state
        when "authorizationStateWaitPhoneNumber"
          phone = @phone_number.to_s.strip
          phone = prompt("Enter phone number (+countrycode...): ") if phone.empty?
          @td.send_query("@type": "setAuthenticationPhoneNumber", phone_number: phone)
        when "authorizationStateWaitCode"
          code = prompt("Enter Telegram login code: ")
          @td.check_authentication_code(code)
        when "authorizationStateWaitPassword"
          password = prompt("Enter 2FA password: ")
          @td.check_authentication_password(password)
        when "authorizationStateWaitOtherDeviceConfirmation"
          link = update.dig("authorization_state", "link")
          warn "[NTgCalls] Open Telegram > Settings > Devices > Link Desktop Device"
          warn "[NTgCalls] #{link}" if link
        end
      end

      def prompt(label)
        print label
        STDIN.gets.to_s.strip
      end

      def resolve_chat_id(chat)
        text = chat.to_s.strip
        raise Error, "chat is required" if text.empty?

        return text.to_i if text.match?(/\A-?\d+\z/)

        username = text.start_with?("@") ? text : "@#{text}"
        result = @td.raw!("@type": "searchPublicChat", username: username.delete_prefix("@"))
        chat_id = result["id"].to_i
        raise Error, "unable to resolve chat '#{chat}'" if chat_id.zero?

        chat_id
      end

      def fetch_input_group_call(chat_id)
        chat = @td.raw!("@type": "getChat", chat_id: chat_id)
        video_chat = chat["video_chat"] || {}
        group_call_id = video_chat["group_call_id"] || dig_group_call_id(video_chat)
        raise Error, "no active voice chat found for chat_id=#{chat_id}" if group_call_id.to_i.zero?

        access_hash = video_chat["group_call_access_hash"] || dig_group_call_access_hash(video_chat)
        {
          "@type" => "inputGroupCall",
          "id" => group_call_id.to_i,
          "access_hash" => access_hash.to_i
        }
      end

      def try_join_group_call(input_group_call:, local_offer:, audio_source_id:, invite_hash:)
        candidates = [
          {
            "@type": "joinGroupCall",
            "group_call_id": input_group_call["id"],
            "participant_id": nil,
            "audio_source_id": audio_source_id,
            "payload": local_offer,
            "is_muted": false,
            "is_my_video_enabled": false,
            "invite_hash": invite_hash.to_s
          },
          {
            "@type": "joinGroupCall",
            "input_group_call": input_group_call,
            "join_parameters": {
              "@type": "groupCallJoinParameters",
              "payload": local_offer,
              "audio_source_id": audio_source_id,
              "is_muted": false,
              "is_my_video_enabled": false,
              "invite_hash": invite_hash.to_s
            }
          }
        ]

        last_error = nil
        candidates.each do |query|
          response = @td.raw(query)
          return response unless response.is_a?(Hash) && response["@type"] == "error"

          last_error = response["message"].to_s
        end
        raise Error, "joinGroupCall failed: #{last_error}"
      end

      def extract_join_payload(response)
        return response["text"] if response["text"].is_a?(String)
        return response["payload"] if response["payload"].is_a?(String)

        group_call_info = response["group_call_info"] || response["groupCallInfo"] || {}
        return group_call_info["payload"] if group_call_info["payload"].is_a?(String)
        return group_call_info["params"] if group_call_info["params"].is_a?(String)

        params = response["params"] || response["connection_params"]
        return params if params.is_a?(String)

        ""
      end

      def deterministic_audio_source_id(chat_id)
        seed = "#{chat_id}:#{Process.pid}:#{SecureRandom.hex(4)}"
        value = seed.each_byte.reduce(0) { |acc, b| ((acc * 131) + b) & 0x7fffffff }
        value.zero? ? 1 : value
      end

      def dig_group_call_id(video_chat)
        group_call = video_chat["group_call"] || {}
        group_call["id"]
      end

      def dig_group_call_access_hash(video_chat)
        group_call = video_chat["group_call"] || {}
        group_call["access_hash"]
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
