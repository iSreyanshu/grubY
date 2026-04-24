module GrubY
  module Filters
    def self.text
      ->(ctx) { !ctx.text.to_s.strip.empty? }
    end

    def self.command(cmd)
      expected = cmd.to_s
      ->(ctx) { ctx.command == expected }
    end

    def self.regex(r)
      ->(ctx) { !!(ctx.text =~ r) }
    end

    def self.private_chat
      ->(ctx) { ctx.message&.chat&.type == "private" }
    end

    def self.group_chat
      ->(ctx) { ["group", "supergroup"].include?(ctx.message&.chat&.type) }
    end
  end
end

