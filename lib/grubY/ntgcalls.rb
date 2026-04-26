require "json"
require "open3"
require "thread"
require "timeout"

module GrubY
  module NTgCalls
    class BridgeError < StandardError; end

    class Bridge
      DEFAULT_TIMEOUT = 30

      attr_reader :python_bin, :script_path

      def initialize(
        api_id:,
        api_hash:,
        session_name: "gruby_ntgcalls",
        session_string: nil,
        bot_token: nil,
        workdir: "storage/ntgcalls",
        auto_login: true,
        start_calls: true,
        python_bin: ENV.fetch("GRUBY_NTGCALLS_PYTHON", "python"),
        script_path: File.expand_path("ntgcalls/bridge.py", __dir__)
      )
        @bootstrap = {
          api_id: api_id,
          api_hash: api_hash,
          session_name: session_name,
          session_string: session_string,
          bot_token: bot_token,
          workdir: workdir,
          auto_login: auto_login,
          start_calls: start_calls
        }
        @python_bin = python_bin
        @script_path = script_path
        @lock = Mutex.new
      end

      def start
        return self if running?

        raise BridgeError, "Bridge script not found at #{script_path}" unless File.exist?(script_path)

        @stdin, @stdout, @stderr, @wait_thr = Open3.popen3(python_bin, script_path)
        boot = request("init", @bootstrap, timeout: 60)
        raise BridgeError, boot["error"].to_s unless boot["ok"]

        self
      end

      def stop
        return self unless running?

        begin
          request("shutdown", {}, timeout: 15)
        rescue StandardError
        end

        [@stdin, @stdout, @stderr].each do |io|
          begin
            io&.close unless io&.closed?
          rescue IOError
          end
        end
        @wait_thr&.kill
        @stdin = nil
        @stdout = nil
        @stderr = nil
        @wait_thr = nil
        self
      end

      def running?
        @wait_thr && @wait_thr.alive?
      end

      def play(chat_id:, stream:, auto_start: true, invite_hash: nil, join_as: nil)
        payload = {
          chat_id: chat_id,
          stream: stream,
          auto_start: auto_start,
          invite_hash: invite_hash,
          join_as: join_as
        }
        request!("play", payload, timeout: 60)
      end

      def pause(chat_id:)
        request!("pause", { chat_id: chat_id })
      end

      def resume(chat_id:)
        request!("resume", { chat_id: chat_id })
      end

      def mute(chat_id:)
        request!("mute", { chat_id: chat_id })
      end

      def unmute(chat_id:)
        request!("unmute", { chat_id: chat_id })
      end

      def leave_call(chat_id:, close: false)
        request!("leave_call", { chat_id: chat_id, close: close })
      end

      def change_volume_call(chat_id:, volume:)
        request!("change_volume_call", { chat_id: chat_id, volume: volume })
      end

      def get_participants(chat_id:)
        request!("get_participants", { chat_id: chat_id })
      end

      def start_calls
        request!("start_calls", {})
      end

      def auth_status
        request!("auth_status", {})
      end

      def auth_send_code(phone:, force_sms: false)
        request!("auth_send_code", { phone: phone, force_sms: force_sms })
      end

      def auth_sign_in(phone: nil, code: nil, password: nil, bot_token: nil, phone_code_hash: nil)
        request!(
          "auth_sign_in",
          {
            phone: phone,
            code: code,
            password: password,
            bot_token: bot_token,
            phone_code_hash: phone_code_hash
          }
        )
      end

      def auth_export_session
        request!("auth_export_session", {})
      end

      def tl_pretty(obj:, indent: nil)
        request!("tl_pretty", { obj: obj, indent: indent })
      end

      def tl_serialize_bytes(data:)
        request!("tl_serialize_bytes", { data: data })
      end

      def tl_serialize_datetime(value:)
        request!("tl_serialize_datetime", { value: value })
      end

      def call(method_name, args: [], kwargs: {})
        request!("call_method", { method: method_name, args: args, kwargs: kwargs })
      end

      def ntg_call(method_name, args: [], kwargs: {})
        request!("call_ntg", { method: method_name, args: args, kwargs: kwargs })
      end

      def pytgcalls_methods
        request!("list_pytgcalls_methods", {})
      end

      def ntgcalls_methods
        request!("list_ntgcalls_methods", {})
      end

      def method_missing(name, *args, **kwargs, &block)
        return super if block

        call(name.to_s, args: args, kwargs: kwargs)
      rescue BridgeError
        super
      end

      def respond_to_missing?(_name, _include_private = false)
        true
      end

      private

      def request!(action, payload = {}, timeout: DEFAULT_TIMEOUT)
        response = request(action, payload, timeout: timeout)
        return response if response["ok"]

        raise BridgeError, "#{response['error']} (#{response['error_type']})"
      end

      def request(action, payload = {}, timeout: DEFAULT_TIMEOUT)
        raise BridgeError, "Bridge is not running" unless running?

        raw = nil
        @lock.synchronize do
          @stdin.write({ action: action, payload: payload }.to_json + "\n")
          @stdin.flush

          begin
            Timeout.timeout(timeout) { raw = @stdout.gets }
          rescue Timeout::Error
            raise BridgeError, "Bridge request timeout on action=#{action}"
          end
        end

        raise BridgeError, "Bridge closed unexpectedly" if raw.nil?

        JSON.parse(raw)
      rescue JSON::ParserError => e
        raise BridgeError, "Invalid bridge response: #{e.message}"
      end
    end

    class RBtgCalls < Bridge; end
  end
end
