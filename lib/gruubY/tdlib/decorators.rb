module GrubY
  module TDLib
    module Decorators
      def initializer(filter: nil, position: nil, timeout: nil, &block)
        add_handler("initializer", filter: filter, position: position, timeout: timeout, &block)
      end

      def finalizer(filter: nil, position: nil, timeout: nil, &block)
        add_handler("finalizer", filter: filter, position: position, timeout: timeout, &block)
      end

      def on_message(filter: nil, position: nil, timeout: nil, &block)
        add_handler("updateNewMessage", filter: filter, position: position, timeout: timeout, inner_object: true, &block)
      end
    end
  end
end
