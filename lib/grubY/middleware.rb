module GrubY
  class Middleware
    def initialize
      @stack = []
    end

    def use(&block)
      @stack << block
    end

    def run(ctx, &final)
      chain = @stack.reverse.inject(final) do |nxt, mw|
        proc { mw.call(ctx, nxt) }
      end
      chain.call
    end
  end
end
