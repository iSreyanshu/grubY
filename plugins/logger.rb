def self.register(bot)
  bot.use do |ctx, nxt|
    username = ctx.user&.username || ctx.user&.first_name || "unknown"
    puts "[LOG] #{username}: #{ctx.update}"
    nxt.call
  end
end
