module GrubY
  module Bound
    def self.bind(ctx)
      {
        send: ->(text){ ctx.reply(text) },
        raw: ->(m,p){ ctx.raw(m,p) }
      }
    end
  end
end

