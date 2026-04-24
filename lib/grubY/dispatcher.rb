module GrubY
  class Dispatcher
    def initialize
      @handlers = {}
      @next_handler_id = 1
    end

    def on(event, filter=nil, &block)
      id = @next_handler_id
      @next_handler_id += 1
      (@handlers[event] ||= []) << { id: id, filter: filter, block: block }
      id
    end

    def off(event, handler_id = nil, &block)
      return false unless @handlers[event]

      before = @handlers[event].length
      @handlers[event].reject! do |entry|
        if handler_id
          entry[:id] == handler_id
        elsif block
          entry[:block] == block
        else
          false
        end
      end
      before != @handlers[event].length
    end

    def trigger(event, ctx)
      return unless @handlers[event]

      @handlers[event].each do |entry|
        filter = entry[:filter]
        handler = entry[:block]
        next if filter && !filter.call(ctx)
        begin
          handler.call(ctx)
        rescue => e
          warn "[DISPATCHER] #{event} handler failed: #{e.class}: #{e.message}"
        end
      end
    end
  end
end
