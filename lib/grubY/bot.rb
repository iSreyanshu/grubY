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

    def on(event, filter=nil, &block)
      @dispatcher.on(event, filter, &block)
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
          if update["message"]
            @dispatcher.trigger(:message, ctx)
          elsif update["callback_query"]
            @dispatcher.trigger(:callback, ctx)
          end
        end
      end
    end
  end
end

