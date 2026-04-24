require_relative "bot"
require_relative "group_manager"

module GrubY
  class Client
    attr_reader :bot, :api, :session, :group_manager

    def initialize(token, session: Session.new, polling_timeout: 30)
      @bot = Bot.new(token, session: session)
      @api = @bot.api
      @session = session
      @group_manager = GroupManager.new(@api, session: @session)
      @polling_timeout = polling_timeout
      @polling_thread = nil
      @running = false
    end

    def start
      return if @running

      @running = true
      start_polling
      self
    end

    def stop
      @running = false
      @polling_thread&.kill
      @polling_thread = nil
      self
    end

    def restart
      stop
      start
    end

    def connect
      start
    end

    def disconnect
      stop
    end

    def run
      start
      idle
      stop
    end

    def terminate
      stop
    end

    def add_handler(event, filter=nil, &block)
      @bot.on(event, filter, &block)
    end

    def remove_handler(event, handler_id = nil, &block)
      @bot.remove_handler(event, handler_id, &block)
    end

    def on(event, filter=nil, &block)
      add_handler(event, filter, &block)
    end

    def use(&block)
      @bot.use(&block)
    end

    def use_plugin(path)
      @bot.use_plugin(path)
    end

    def process_update(update)
      @bot.process_update(update)
    end

    def stop_transmission
      true
    end

    def export_session_string
      @session.to_h.to_json
    end

    def set_parse_mode(mode)
      @session.set("__parse_mode__", mode.to_s)
      mode
    end

    def get_parse_mode
      @session.get("__parse_mode__")
    end

    def set_dc(dc_id, config = {})
      @session.set("dc:#{dc_id}", config)
      config
    end

    def get_dc_option(dc_id)
      @session.get("dc:#{dc_id}")
    end

    def get_session
      @session
    end

    def get_file(file_id)
      @api.get_file(file_id)
    end

    def idle
      @idle = true
      trap_signals
      sleep 0.3 while @idle
    ensure
      @idle = false
    end

    def self.compose(*clients, &block)
      clients.each(&:start)
      block.call if block
      clients.each(&:idle)
    ensure
      clients.each(&:stop)
    end

    [
      :send_message, :forward_message, :forward_messages, :forward_media_group,
      :copy_message, :copy_messages, :copy_media_group, :send_photo, :send_audio,
      :send_document, :send_video, :send_animation, :send_voice, :send_video_note,
      :send_media_group, :send_paid_media, :send_location, :send_venue,
      :send_contact, :send_poll, :send_checklist, :send_dice, :send_message_draft,
      :send_chat_action, :set_message_reaction, :send_reaction,
      :answer_callback_query, :edit_message_text, :delete_message,
      :delete_messages, :get_updates, :download_file
    ].each do |api_method|
      define_method(api_method) do |*args, **kwargs|
        @api.public_send(api_method, *args, **kwargs)
      end
    end

    def method_missing(name, *args, **kwargs, &block)
      return super unless @api.respond_to?(name)

      @api.public_send(name, *args, **kwargs, &block)
    end

    def respond_to_missing?(name, include_private = false)
      @api.respond_to?(name) || super
    end

    private

    def start_polling
      offset = nil
      @polling_thread = Thread.new do
        while @running
          begin
            updates = @api.get_updates(offset, timeout: @polling_timeout) || []
            updates.each do |update|
              offset = update["update_id"].to_i + 1
              process_update(update)
            end
          rescue => e
            warn "[CLIENT] polling error: #{e.class}: #{e.message}"
            sleep 1
          end
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
