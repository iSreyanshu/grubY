require_relative "../lib/grubY"
require_relative "../config/config"

client = GrubY::Client.new(Config::TOKEN)
gm = client.group_manager

client.use_plugin("../plugins/logger.rb")

HELP = <<~TXT
  Commands:
  /start - boot check
  /help - show this help
  /echo <text> - echo text
  /md <text> - markdown v2 safe send
  /html <text> - html safe send
  /poll - send sample poll
  /media - send sample media methods
  /whoami - show user + chat info
  /warn <user_id> [reason] - warn user
  /mute <user_id> - mute user
  /unmute <user_id> - unmute user
  /ban <user_id> - ban user
  /unban <user_id> - unban user
  /pin - pin current message
  /unpin - unpin latest pinned message
  /lock - lock group
  /unlock - unlock group
  /reaction - set reaction on replied message
TXT

client.on(:message, GrubY::Filters.command("start")) do |ctx|
  ctx.reply("GrubY client started. Use /help")
end

client.on(:message, GrubY::Filters.command("help")) do |ctx|
  ctx.reply(HELP)
end

client.on(:message, GrubY::Filters.command("echo")) do |ctx|
  text = ctx.command_args.join(" ")
  ctx.reply(text.empty? ? "Usage: /echo hello" : text)
end

client.on(:message, GrubY::Filters.command("md")) do |ctx|
  text = ctx.command_args.join(" ")
  safe = GrubY::API.escape_markdown_v2(text.empty? ? "markdown_v2 demo" : text)
  client.send_message(ctx.chat_id, "*Safe:* #{safe}", parse_mode: "MarkdownV2")
end

client.on(:message, GrubY::Filters.command("html")) do |ctx|
  text = ctx.command_args.join(" ")
  safe = GrubY::API.escape_html(text.empty? ? "<b>html</b> demo" : text)
  client.send_message(ctx.chat_id, "<b>Safe:</b> #{safe}", parse_mode: "HTML")
end

client.on(:message, GrubY::Filters.command("poll")) do |ctx|
  client.send_poll(
    ctx.chat_id,
    "Pick stack",
    [
      { text: "Ruby" },
      { text: "Python" },
      { text: "Go" }
    ],
    is_anonymous: false,
    allows_multiple_answers: true
  )
end

client.on(:message, GrubY::Filters.command("media")) do |ctx|
  client.send_chat_action(ctx.chat_id, "typing")
  ctx.reply("Try these API methods from code: send_photo/send_audio/send_document/send_video/send_animation/send_voice/send_video_note/send_media_group/send_paid_media")
end

client.on(:message, GrubY::Filters.command("whoami")) do |ctx|
  user = ctx.user
  chat = ctx.message&.chat
  text = "user_id=#{user&.id} username=@#{user&.username} chat_id=#{chat&.id} chat_type=#{chat&.type}"
  ctx.reply(text)
end

client.on(:message, GrubY::Filters.command("warn")) do |ctx|
  user_id = ctx.command_args[0]&.to_i
  reason = ctx.command_args[1..]&.join(" ")
  if user_id.nil? || user_id.zero?
    ctx.reply("Usage: /warn <user_id> [reason]")
    next
  end

  result = gm.enforce_warns(ctx.chat_id, user_id, reason: reason)
  if result[:action] == :kick
    ctx.reply("User #{user_id} kicked. warn limit reached.")
  else
    ctx.reply("Warned #{user_id}. #{result[:warns]}/#{result[:limit]}")
  end
end

client.on(:message, GrubY::Filters.command("mute")) do |ctx|
  user_id = ctx.command_args[0]&.to_i
  next ctx.reply("Usage: /mute <user_id>") if user_id.nil? || user_id.zero?

  gm.mute(ctx.chat_id, user_id)
  ctx.reply("Muted #{user_id}")
end

client.on(:message, GrubY::Filters.command("unmute")) do |ctx|
  user_id = ctx.command_args[0]&.to_i
  next ctx.reply("Usage: /unmute <user_id>") if user_id.nil? || user_id.zero?

  gm.unmute(ctx.chat_id, user_id)
  ctx.reply("Unmuted #{user_id}")
end

client.on(:message, GrubY::Filters.command("ban")) do |ctx|
  user_id = ctx.command_args[0]&.to_i
  next ctx.reply("Usage: /ban <user_id>") if user_id.nil? || user_id.zero?

  gm.ban(ctx.chat_id, user_id)
  ctx.reply("Banned #{user_id}")
end

client.on(:message, GrubY::Filters.command("unban")) do |ctx|
  user_id = ctx.command_args[0]&.to_i
  next ctx.reply("Usage: /unban <user_id>") if user_id.nil? || user_id.zero?

  gm.unban(ctx.chat_id, user_id, only_if_banned: true)
  ctx.reply("Unbanned #{user_id}")
end

client.on(:message, GrubY::Filters.command("pin")) do |ctx|
  gm.pin(ctx.chat_id, ctx.message.message_id)
  ctx.reply("Pinned this message")
end

client.on(:message, GrubY::Filters.command("unpin")) do |ctx|
  gm.unpin(ctx.chat_id)
  ctx.reply("Unpinned latest message")
end

client.on(:message, GrubY::Filters.command("lock")) do |ctx|
  gm.lock(ctx.chat_id)
  ctx.reply("Group locked")
end

client.on(:message, GrubY::Filters.command("unlock")) do |ctx|
  gm.unlock(ctx.chat_id)
  ctx.reply("Group unlocked")
end

client.on(:message, GrubY::Filters.command("reaction")) do |ctx|
  message_id = ctx.message.message_id
  client.send_reaction(ctx.chat_id, message_id, reaction: [{ type: "emoji", emoji: "\u{1F525}" }])
  ctx.reply("Reaction sent")
end

client.on(:message, GrubY::Filters.regex(/hello/i)) do |ctx|
  ctx.reply("hello world from GrubY")
end

client.run

