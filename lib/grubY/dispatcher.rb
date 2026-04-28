module GrubY
  class Dispatcher
    def initialize
      @handlers = {}
      @next_handler_id = 1
    end

    def on(event, filter = nil, group: 0, &block)
      id = @next_handler_id
      @next_handler_id += 1
      (@handlers[event] ||= []) << { id: id, filter: filter, block: block, group: group.to_i }
      @handlers[event].sort_by! { |h| h[:group] }
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
        if filter
          pass = begin
            if defined?(GrubY::Filters::Filter) && filter.is_a?(GrubY::Filters::Filter)
              filter.call(nil, nil, ctx)
            elsif filter.respond_to?(:call)
              filter.call(ctx)
            else
              true
            end
          rescue ArgumentError
            filter.call(nil, nil, ctx)
          end
          next unless pass
        end
        begin
          handler.call(ctx)
        rescue => e
          warn "[DISPATCHER] #{event} handler failed: #{e.class}: #{e.message}"
        end
      end
    end
  end
end
