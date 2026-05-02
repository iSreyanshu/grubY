require_relative "api"
require_relative "dispatcher"
require_relative "middleware"
require_relative "context"
require_relative "plugin"
require_relative "async"
require_relative "session"

module GrubY
  class Bot
    attr_reader :api, :session

    def initialize(token, session: Session.new)
      @api = API.new(token)
      @dispatcher = Dispatcher.new
      @middleware = Middleware.new
      @session = session
    end

    def on(event, filter=nil, group: 0, &block)
      @dispatcher.on(event, filter, group: group, &block)
    end

    def remove_handler(event, handler_id = nil, &block)
      @dispatcher.off(event, handler_id, &block)
    end

    def use(&block)
      @middleware.use(&block)
    end

    def use_plugin(path)
      Plugin.load(self, path)
    end

    def process_update(update)
      Async.run do
        ctx = Context.new(update, @api, @session)

        @middleware.run(ctx) do
          @dispatcher.trigger(:raw_update, ctx)
          dispatch_update_events(update, ctx)
        end
      end
    rescue => e
      error_ctx = Context.new({ "error" => e }, @api, @session)
      @dispatcher.trigger(:error, error_ctx)
      warn "[BOT] process_update error: #{e.class}: #{e.message}"
    end

    def emit(event, payload = {})
      ctx = Context.new(payload, @api, @session)
      @dispatcher.trigger(event, ctx)
    end

    private

    def dispatch_update_events(update, ctx)
      mapping = {
        "message" => :message,
        "edited_message" => :edited_message,
        "business_message" => :business_message,
        "edited_business_message" => :edited_business_message,
        "deleted_messages" => :deleted_messages,
        "deleted_business_messages" => :deleted_business_messages,
        "message_reaction_count" => :message_reaction_count,
        "message_reaction" => :message_reaction,
        "business_connection" => :business_connection,
        "story" => :story,
        "callback_query" => :callback_query,
        "chat_boost" => :chat_boost,
        "chat_join_request" => :chat_join_request,
        "chat_member_updated" => :chat_member_updated,
        "chosen_inline_result" => :chosen_inline_result,
        "inline_query" => :inline_query,
        "poll" => :poll,
        "pre_checkout_query" => :pre_checkout_query,
        "purchased_paid_media" => :purchased_paid_media,
        "shipping_query" => :shipping_query,
        "user_status" => :user_status,
        "managed_bot_updated" => :managed_bot
      }

      mapping.each do |key, event|
        @dispatcher.trigger(event, ctx) if update.key?(key)
      end
      @dispatcher.trigger(:callback, ctx) if update.key?("callback_query")
    end
  end
end
