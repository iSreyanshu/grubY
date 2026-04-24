# GrubY

Modern Ruby Telegram toolkit with:

- `GrubY::Client` (Bot API runtime)
- `GrubY::TDLib::Client` (tdjson native runtime, pytdbot-inspired)

## Install

```bash
bundle install
```

## What Is New

- TDLib internals upgraded with a dedicated `TdJson` wrapper
- Decorator-style hooks for TDLib:
  - `initializer`
  - `finalizer`
  - `on_message`
- Queue workers and handler timeout support
- Better authorization lifecycle handling
- Multi-client support utility: `GrubY::TDLib::ClientManager`
- Static docs page: `docs.html`
- CI workflows for TDLib build and gem publish

## Bot API Quick Start

```ruby
require_relative "lib/grubY"

client = GrubY::Client.new("BOT_TOKEN")
client.on(:message, GrubY::Filters.command("start")) { |ctx| ctx.reply("Bot is alive") }
client.run
```

## TDLib Quick Start

```ruby
client = GrubY::TDLib::Client.new(
  api_id: ENV.fetch("TD_API_ID").to_i,
  api_hash: ENV.fetch("TD_API_HASH"),
  bot_token: ENV["TD_BOT_TOKEN"],
  tdjson_path: ENV["TDJSON_PATH"],
  workers: 4,
  default_handler_timeout: 10
)

client.initializer do |update|
  # runs before normal handlers
end

client.on_message do |message|
  # message object from updateNewMessage
end

client.finalizer do |update|
  # always runs after handler pipeline
end

client.on("clientReady") { puts "TDLib ready" }
client.run
```

## TDLib Paths

Supported shared libraries:

- Linux: `libtdjson.so`
- macOS: `libtdjson.dylib`
- Windows: `tdjson.dll`

Provide via:

- `TDJSON_PATH` env var
- `tdjson_path:` constructor argument

### GitHub Build Se TDJSON Kaise Lo

1. Tag push karo (example: `v0.2.1`) ya manually `Release TDJSON` workflow run karo.
2. GitHub Release assets se apne OS ka zip download karo:
   - `tdjson-linux-x64.zip`
   - `tdjson-macos-x64.zip`
   - `tdjson-windows-x64.zip`
3. Extract karke repo me copy karo:
   - Linux: `vendor/tdlib/linux/libtdjson.so`
   - macOS: `vendor/tdlib/macos/libtdjson.dylib`
   - Windows: `vendor/tdlib/windows/tdjson.dll`
4. Optional: `TDJSON_PATH` set karo agar custom path use karna hai.

`GrubY::TDLib::Native` ab `vendor/tdlib/...` paths se bhi auto-detect karta hai.

## Examples

- `example/bot.rb`
- `example/tdlib.rb`
- `example/userbot.rb` (phone/QR login + outgoing `!hi` edit flow)
