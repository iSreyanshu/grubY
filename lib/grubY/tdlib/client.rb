require "json"
require "logger"
require "timeout"
require "fileutils"
require "thread"
require_relative "decorators"
require_relative "errors"
require_relative "group_manager"
require_relative "tdjson"

module GrubY
  module TDLib
    class Client
      include Decorators

      Handler = Struct.new(
        :id,
        :update_type,
        :block,
        :filter,
        :position,
        :inner_object,
        :timeout,
        keyword_init: true
      )

      attr_reader :api_id, :api_hash, :database_directory, :files_directory, :group_manager
      attr_reader :authorization_state, :td_options

      def initialize(
        api_id:,
        api_hash:,
        database_directory: "storage/tdlib",
        files_directory: "storage/tdlib/files",
        phone_number: nil,
        bot_token: nil,
        tdjson_path: nil,
        database_encryption_key: "",
        use_test_dc: false,
        system_language_code: "en",
        device_model: "GrubY",
        system_version: RUBY_PLATFORM,
        application_version: "0.2.0",
        options: {},
        workers: 4,
        queue_size: 1_000,
        default_handler_timeout: nil,
        td_verbosity: 1
      )
        @api_id = api_id
        @api_hash = api_hash
        @database_directory = database_directory
        @files_directory = files_directory
        @phone_number = phone_number
        @bot_token = bot_token
        @database_encryption_key = database_encryption_key.to_s
        @use_test_dc = use_test_dc
        @system_language_code = system_language_code
        @device_model = device_model
        @system_version = system_version
        @application_version = application_version
        @td_options = options
        @workers = workers
        @queue_size = queue_size
        @default_handler_timeout = default_handler_timeout
        @logger = Logger.new($stdout)
        @logger.level = Logger::INFO

        @handlers = Hash.new { |h, k| h[k] = [] }
        @next_handler_id = 1
        @pending = {}
        @pending_mutex = Mutex.new
        @sequence = 0
        @running = false
        @authorized = false
        @authorization_state = nil
        @updates_thread = nil
        @workers_threads = []
        @queue = Queue.new
        @group_manager = GroupManager.new(self)
        @local_handlers = {
          "updateAuthorizationState" => method(:process_authorization_update),
          "updateOption" => method(:process_update_option)
        }

        @tdjson = TdJson.new(lib_path: tdjson_path, verbosity: td_verbosity)
        @native_client = @tdjson.create_client_id
      end

      def start
        return self if @running

        ensure_native_client!
        ensure_storage!
        verify_arguments!
        @running = true
        set_options
        boot_authorization_state
        start_update_loop
        start_workers
        self
      end

      alias connect start

      def stop
        return self unless @running

        @running = false
        @updates_thread&.kill
        @updates_thread = nil
        @workers_threads.each(&:kill)
        @workers_threads.clear
        send_query("@type": "close")
        @tdjson.destroy(@native_client) if @native_client
        @native_client = nil
        self
      end

      alias disconnect stop
      alias terminate stop
      alias initialize_client start

      def restart
        stop
        start
      end

      def run
        start
        idle
        stop
      end

      def idle
        @idle = true
        trap_signals
        sleep 0.3 while @idle
      ensure
        @idle = false
      end

      def add_handler(
        update_type = nil,
        filter: nil,
        position: nil,
        inner_object: false,
        timeout: nil,
        &block
      )
        raise ArgumentError, "handler block is required" unless block

        id = @next_handler_id
        @next_handler_id += 1
        type = update_type.to_s
        handler = Handler.new(
          id: id,
          update_type: type,
          block: block,
          filter: filter,
          position: position,
          inner_object: inner_object,
          timeout: timeout
        )
        @handlers[type] << handler
        sort_handlers(type)
        id
      end

      def on(update_type = nil, **options, &block)
        add_handler(update_type, **options, &block)
      end

      def remove_handler(handler_id = nil, &block)
        removed = false
        @handlers.each_key do |type|
          before = @handlers[type].length
          @handlers[type].delete_if do |handler|
            (handler_id && handler.id == handler_id) || (block && handler.block == block)
          end
          removed ||= before != @handlers[type].length
        end
        removed
      end

      def send_query(query)
        @tdjson.send(@native_client, with_extra(query))
      end

      def execute(query)
        @tdjson.execute(@native_client, stringify_keys(query))
      end

      def invoke(query, timeout: 30.0, poll_interval: 0.05)
        tagged = with_extra(query)
        tag = extra_id(tagged["@extra"])
        @pending_mutex.synchronize { @pending[tag] = nil }
        @tdjson.send(@native_client, tagged)

        deadline = Time.now + timeout
        while Time.now < deadline
          consume_once(poll_interval)
          value = @pending_mutex.synchronize { @pending[tag] }
          return value if value
        end
        raise Timeout::Error, "TDLib response timeout for #{query[:@type] || query['@type']}"
      ensure
        @pending_mutex.synchronize { @pending.delete(tag) } if tag
      end

      def raw(query, timeout: 30.0, poll_interval: 0.05)
        invoke(query, timeout: timeout, poll_interval: poll_interval)
      end

      def raw!(query, timeout: 30.0, poll_interval: 0.05)
        result = raw(query, timeout: timeout, poll_interval: poll_interval)
        if result.is_a?(Hash) && result["@type"] == "error"
          message = result["message"] || "unknown TDLib error"
          raise StandardError, "TDLib raw call failed: #{message}"
        end
        result
      end

      def authorized?
        @authorized
      end

      def check_authentication_code(code)
        send_query("@type": "checkAuthenticationCode", code: code)
      end

      alias sign_in check_authentication_code

      def check_authentication_password(password)
        send_query("@type": "checkAuthenticationPassword", password: password)
      end

      alias check_password check_authentication_password

      def check_authentication_bot_token(token = @bot_token)
        send_query("@type": "checkAuthenticationBotToken", token: token)
      end

      alias sign_in_bot check_authentication_bot_token

      def send_phone_number_code(phone_number, settings: nil)
        payload = { "@type": "setAuthenticationPhoneNumber", phone_number: phone_number }
        payload[:settings] = settings if settings
        send_query(payload)
      end

      def resend_phone_number_code
        send_query("@type": "resendAuthenticationCode")
      end

      def send_recovery_code
        send_query("@type": "requestAuthenticationPasswordRecovery")
      end

      def recover_password(recovery_code, new_password: nil, new_hint: nil)
        send_query(
          "@type": "recoverAuthenticationPassword",
          recovery_code: recovery_code,
          new_password: new_password,
          new_hint: new_hint
        )
      end

      def log_out
        send_query("@type": "logOut")
      end

      def get_active_sessions
        invoke("@type": "getActiveSessions")
      end

      def reset_session(session_hash)
        send_query("@type": "terminateSession", session_id: session_hash)
      end

      def reset_sessions
        send_query("@type": "terminateAllOtherSessions")
      end

      def set_log_verbosity(level)
        Native.td_set_log_verbosity_level(level.to_i)
      end

      def method_missing(name, *args, **kwargs, &block)
        return super if block
        return super unless args.empty?

        type = self.class.camelize_td_type(name)
        invoke({ "@type": type }.merge(kwargs))
      end

      def respond_to_missing?(_name, _include_private = false)
        true
      end

      def native_client_key
        @native_client.to_i
      end

      def self.compose(*clients, &block)
        clients.each(&:start)
        block.call if block
        clients.each(&:idle)
      ensure
        clients.each(&:stop)
      end

      def self.camelize_td_type(name)
        parts = name.to_s.split("_")
        parts.first + parts[1..].map(&:capitalize).join
      end

      private

      def ensure_storage!
        FileUtils.mkdir_p(@database_directory)
        FileUtils.mkdir_p(@files_directory)
      end

      def ensure_native_client!
        @native_client ||= @tdjson.create_client_id
      end

      def verify_arguments!
        raise TypeError, "api_id must be an Integer" unless @api_id.is_a?(Integer)
        raise TypeError, "api_hash must be a String" unless @api_hash.is_a?(String)
      end

      def boot_authorization_state
        send_query("@type": "getAuthorizationState")
      end

      def set_options
        return unless @td_options.is_a?(Hash)

        @td_options.each do |name, value|
          option_payload = case value
                           when String
                             { "@type" => "optionValueString", "value" => value }
                           when Integer
                             { "@type" => "optionValueInteger", "value" => value }
                           when TrueClass, FalseClass
                             { "@type" => "optionValueBoolean", "value" => value }
                           else
                             next
                           end
          send_query("@type": "setOption", "name": name.to_s, "value": option_payload)
        end
      end

      def start_update_loop
        @updates_thread = Thread.new do
          while @running
            begin
              consume_once(0.5)
            rescue => e
              warn "[TDLIB] update loop error: #{e.class}: #{e.message}"
              sleep 0.2
            end
          end
        end
      end

      def start_workers
        worker_count = @workers.to_i
        return if worker_count <= 0

        @workers_threads = worker_count.times.map do
          Thread.new do
            while @running
              begin
                update = @queue.pop
                run_update(update)
              rescue StandardError => e
                warn "[TDLIB] worker failed: #{e.class}: #{e.message}"
              end
            end
          end
        end
      end

      def consume_once(timeout)
        update = @tdjson.receive(@native_client, timeout: timeout)
        return unless update
        handle_incoming(update)
      end

      def handle_incoming(update)
        update_extra_id = extra_id(update["@extra"])
        if update_extra_id && @pending_mutex.synchronize { @pending.key?(update_extra_id) }
          @pending_mutex.synchronize { @pending[update_extra_id] = update }
          return
        end

        local_handler = @local_handlers[update["@type"]]
        local_handler.call(update) if local_handler

        if @workers_threads.empty?
          run_update(update)
          return
        end

        if @queue.size > @queue_size
          warn "[TDLIB] queue is full; dropping update #{update["@type"]}"
          return
        end

        @queue << update
      end

      def process_authorization_update(update)
        return unless update["@type"] == "updateAuthorizationState"

        state = update.dig("authorization_state", "@type")
        @authorization_state = state
        case state
        when "authorizationStateWaitTdlibParameters"
          set_options
          send_query(
            "@type": "setTdlibParameters",
            parameters: {
              "@type": "tdlibParameters",
              use_test_dc: @use_test_dc,
              database_directory: @database_directory,
              files_directory: @files_directory,
              use_file_database: true,
              use_chat_info_database: true,
              use_message_database: true,
              use_secret_chats: true,
              api_id: @api_id,
              api_hash: @api_hash,
              system_language_code: @system_language_code,
              device_model: @device_model,
              system_version: @system_version,
              application_version: @application_version
            }
          )
        when "authorizationStateWaitEncryptionKey"
          send_query(
            "@type": "checkDatabaseEncryptionKey",
            encryption_key: @database_encryption_key
          )
        when "authorizationStateWaitPhoneNumber"
          if @bot_token
            check_authentication_bot_token(@bot_token)
          elsif @phone_number
            send_query("@type": "setAuthenticationPhoneNumber", phone_number: @phone_number)
          end
        when "authorizationStateWaitCode"
          run_update("@type" => "authCodeNeeded", "hint" => "Call check_authentication_code(code)")
        when "authorizationStateWaitPassword"
          run_update("@type" => "authPasswordNeeded", "hint" => "Call check_authentication_password(password)")
        when "authorizationStateWaitRegistration"
          run_update("@type" => "authRegistrationNeeded")
        when "authorizationStateReady"
          @authorized = true
          run_update("@type" => "clientReady")
        when "authorizationStateClosed"
          @authorized = false
        end
      end

      def process_update_option(update)
        value = update["value"]
        parsed = if value.is_a?(Hash)
                   value["value"]
                 else
                   value
                 end
        @td_options[update["name"]] = parsed
      end

      def run_update(update)
        run_handlers_for("initializer", update)
        run_handlers_for(update["@type"].to_s, update)
      rescue StopHandlers
      ensure
        run_handlers_for("finalizer", update)
      end

      def run_handlers_for(type, update)
        handlers = @handlers[type]
        return if handlers.nil? || handlers.empty?

        handlers.each do |handler|
          payload = handler.inner_object ? extract_inner_object(update) : update
          next unless pass_filter?(handler, payload)

          call_handler(handler, payload)
        rescue StopHandlers
          raise
        rescue StandardError => e
          warn "[TDLIB] handler failed: #{e.class}: #{e.message}"
        end
      end

      def extract_inner_object(update)
        return update["message"] if update["@type"] == "updateNewMessage"

        update
      end

      def pass_filter?(handler, payload)
        return true unless handler.filter.respond_to?(:call)

        handler.filter.call(payload)
      end

      def call_handler(handler, payload)
        timeout = handler.timeout || @default_handler_timeout
        if timeout
          Timeout.timeout(timeout) { handler.block.call(payload) }
        else
          handler.block.call(payload)
        end
      end

      def sort_handlers(type)
        @handlers[type].sort_by! do |h|
          [h.position.nil? ? 1 : 0, h.position || 0]
        end
      end

      def with_extra(query)
        @sequence += 1
        q = stringify_keys(query)
        q["@extra"] ||= { "id" => "gruby-#{@sequence}" }
        q
      end

      def extra_id(extra)
        return nil if extra.nil?
        return extra["id"] if extra.is_a?(Hash)

        extra
      end

      def stringify_keys(hash)
        hash.each_with_object({}) do |(k, v), out|
          key = k.to_s
          out[key] = case v
                     when Hash
                       stringify_keys(v)
                     when Array
                       v.map { |item| item.is_a?(Hash) ? stringify_keys(item) : item }
                     else
                       v
                     end
        end
      end

      def trap_signals
        %w[INT TERM].each do |sig|
          Signal.trap(sig) { @idle = false }
        rescue ArgumentError
        end
      end
    end
  end
end
