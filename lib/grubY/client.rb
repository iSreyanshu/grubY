require_relative "bot"
require_relative "group_manager"
require_relative "handlers"
require_relative "filters"
require_relative "types/message"
require_relative "types/chat"
require_relative "types/user"

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

      @bot.emit(:connect)
      @running = true
      start_polling
      @bot.emit(:start)
      self
    end

    def stop
      @bot.emit(:stop) if @running
      @running = false
      @polling_thread&.kill
      @polling_thread = nil
      @bot.emit(:disconnect)
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

    def add_handler(handler_or_event, filter=nil, group: 0, &block)
      if handler_or_event.is_a?(GrubY::Handlers::BaseHandler)
        register_handler_object(handler_or_event)
      else
        @bot.on(handler_or_event, filter, group: group, &block)
      end
    end

    def remove_handler(event, handler_id = nil, &block)
      @bot.remove_handler(event, handler_id, &block)
    end

    def on(event, filter=nil, &block)
      add_handler(event, filter, &block)
    end

    {
      on_message: GrubY::Handlers::MessageHandler,
      on_edited_message: GrubY::Handlers::EditedMessageHandler,
      on_business_message: GrubY::Handlers::BusinessMessageHandler,
      on_edited_business_message: GrubY::Handlers::EditedBusinessMessageHandler,
      on_deleted_messages: GrubY::Handlers::DeletedMessagesHandler,
      on_deleted_business_messages: GrubY::Handlers::DeletedBusinessMessagesHandler,
      on_message_reaction_count: GrubY::Handlers::MessageReactionCountHandler,
      on_message_reaction: GrubY::Handlers::MessageReactionHandler,
      on_business_connection: GrubY::Handlers::BusinessConnectionHandler,
      on_story: GrubY::Handlers::StoryHandler,
      on_callback_query: GrubY::Handlers::CallbackQueryHandler,
      on_chat_boost: GrubY::Handlers::ChatBoostHandler,
      on_chat_join_request: GrubY::Handlers::ChatJoinRequestHandler,
      on_chat_member_updated: GrubY::Handlers::ChatMemberUpdatedHandler,
      on_chosen_inline_result: GrubY::Handlers::ChosenInlineResultHandler,
      on_inline_query: GrubY::Handlers::InlineQueryHandler,
      on_poll: GrubY::Handlers::PollHandler,
      on_pre_checkout_query: GrubY::Handlers::PreCheckoutQueryHandler,
      on_purchased_paid_media: GrubY::Handlers::PurchasedPaidMediaHandler,
      on_shipping_query: GrubY::Handlers::ShippingQueryHandler,
      on_user_status: GrubY::Handlers::UserStatusHandler,
      on_start: GrubY::Handlers::StartHandler,
      on_stop: GrubY::Handlers::StopHandler,
      on_connect: GrubY::Handlers::ConnectHandler,
      on_disconnect: GrubY::Handlers::DisconnectHandler,
      on_managed_bot: GrubY::Handlers::ManagedBotUpdatedHandler,
      on_raw_update: GrubY::Handlers::RawUpdateHandler
    }.each do |decorator_name, klass|
      define_method(decorator_name) do |filters = nil, group: 0, &block|
        add_handler(klass.new(block, filters: filters, group: group))
      end
    end

    def on_error(exceptions = nil, filters = nil, group: 0, &block)
      add_handler(
        GrubY::Handlers::ErrorHandler.new(
          block,
          filters: filters,
          group: group,
          exceptions: exceptions
        )
      )
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

    def build_message(data)
      GrubY::Message.new(data, api: @api, client: self)
    end

    def build_chat(data)
      GrubY::Chat.new(data, api: @api, client: self)
    end

    def build_user(data)
      GrubY::User.new(data, api: @api, client: self)
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

    def register_handler_object(handler)
      wrapped = proc do |ctx|
        payload = handler.extract(ctx)
        if handler.filters
          next unless handler.filters.call(handler, self, payload)
        end

        if handler.is_a?(GrubY::Handlers::ErrorHandler)
          error = payload
          allowed = Array(handler.exceptions).compact
          next if !allowed.empty? && !allowed.any? { |klass| error.is_a?(klass) }
          invoke_handler_callback(handler.callback, error, ctx)
        else
          invoke_handler_callback(handler.callback, payload, ctx)
        end
      end

      @bot.on(handler.event, nil, group: handler.group, &wrapped)
    end

    def invoke_handler_callback(callback, payload, ctx)
      return unless callback
      if payload.nil? && ctx.update.is_a?(Hash) && ctx.update.empty?
        case callback.arity
        when 0 then callback.call
        when 1 then callback.call(self)
        else callback.call(self, nil, ctx)
        end
        return
      end

      case callback.arity
      when 0
        callback.call
      when 1
        callback.call(payload)
      when 2
        callback.call(self, payload)
      else
        callback.call(self, payload, ctx)
      end
    end

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
            @bot.emit(:error, { "error" => e })
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
