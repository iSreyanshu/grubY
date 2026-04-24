require_relative "../lib/grubY"

# Set these in your environment before running:
# TD_API_ID=12345
# TD_API_HASH=your_api_hash
# TD_BOT_TOKEN=12345:abc...   (or use TD_PHONE for user auth)
# TDJSON_PATH=/path/to/libtdjson.so|dylib|dll

api_id = ENV["TD_API_ID"]&.to_i
api_hash = ENV["TD_API_HASH"]
bot_token = ENV["TD_BOT_TOKEN"]
phone = ENV["TD_PHONE"]

abort("Missing TD_API_ID or TD_API_HASH") unless api_id && api_hash

client = GrubY::TDLib::Client.new(
  api_id: api_id,
  api_hash: api_hash,
  bot_token: bot_token,
  phone_number: phone,
  tdjson_path: ENV["TDJSON_PATH"],
  workers: 4,
  default_handler_timeout: 10
)

gm = client.group_manager

client.on("clientReady") do
  puts "[TDLIB] ready"
end

client.initializer do |update|
  type = update["@type"]
  puts "[TDLIB] update=#{type}" if type
end

client.on("authCodeNeeded") do
  print "Enter login code: "
  code = STDIN.gets.to_s.strip
  client.check_authentication_code(code)
end

client.on("authPasswordNeeded") do
  print "Enter 2FA password: "
  pass = STDIN.gets.to_s.strip
  client.check_authentication_password(pass)
end

client.on_message do |message|
  chat_id = message["chat_id"]
  content = message.dig("content", "@type")

  next unless content == "messageText"

  text = message.dig("content", "text", "text").to_s
  next unless text.start_with?("/")

  case text
  when "/ping"
    client.sendMessage(
      chat_id: chat_id,
      input_message_content: {
        "@type": "inputMessageText",
        text: { "@type": "formattedText", text: "pong" }
      }
    )
  when "/lock"
    gm.set_slow_mode(chat_id: chat_id, delay: 30)
  when "/title"
    gm.set_chat_title(chat_id: chat_id, title: "GrubY TDLib Room")
  end
end

client.finalizer do |_update|
  # place for metrics/telemetry hooks
end

client.run
