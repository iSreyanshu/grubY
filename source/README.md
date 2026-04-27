## GrubY

A Ruby Telegram wrapper with TDLib:

- `GrubY::Client` (BotAPI runtime)
- `GrubY::TDLib::Client` (tdjson native runtime, pytdbot-inspired)

## Install

```bash
gem install grubY
```

For local development:

```bash
bundle install
```

From this repo directly:

```bash
rake build
gem install ./grubY-0.2.0.gem
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
- CI workflows for TDLib build and gem publish

## BotAPI Quick Start

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
end

client.on_message do |message|
  # Message object from updateNewMessage
end

client.finalizer do |update|
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

## NTgCalls VC Bridge

GrubY includes a bridge for Telegram voice chats via `py-tgcalls` and `ntgcalls`.
Used `Telethon` based backend!

example:

- `example/ntgcalls_demo.rb`
- `example/requirements.txt`

### Install Python deps

```bash
python -m pip install -r example/requirements.txt
```

### Environment

- `TD_API_ID` (required)
- `TD_API_HASH` (required)
- `TD_SESSION_STRING` (Telethon String Session; recommended)
- `VC_CHAT_ID` (required for demo)
- `VC_AUDIO` (required; local file path or URL)

### Run Demo

```bash
ruby example/ntgcalls_demo.rb
```

### Full Method Access

Use `GrubY::NTgCalls::Bridge#call` for additional py-tgcalls methods:

```ruby
bridge.call("record", args: [chat_id, "recorded.raw"])
bridge.call("time", args: [chat_id])
```

Ruby usage via alias:

```ruby
rbt = GrubY::NTgCalls::RBtgCalls.new(api_id: ..., api_hash: ..., session_string: ...)
rbt.start
rbt.play(chat_id: -100123456789, stream: "song.mp3")
rbt.pause(-100123456789)
```

NTgCalls binding methods:

```ruby
bridge.ntg_call("calls")
bridge.ntg_call("cpu_usage")
```

Method discovery:

```ruby
bridge.pytgcalls_methods
bridge.ntgcalls_methods
```

### Non-Interactive Auth Flow (Modern)

Use this when you don't have `TD_SESSION_STRING` yet:

```ruby
bridge = GrubY::NTgCalls::Bridge.new(
  api_id: ENV.fetch("TD_API_ID").to_i,
  api_hash: ENV.fetch("TD_API_HASH"),
  auto_login: false,
  start_calls: false
).start

status = bridge.auth_status
unless status["authorized"]
  sent = bridge.auth_send_code(phone: "+91XXXXXXXXXX")
  # Ask user for code from Telegram App/SMS
  bridge.auth_sign_in(phone: "+91XXXXXXXXXX", code: "12345", phone_code_hash: sent["phone_code_hash"])
end

session = bridge.auth_export_session
puts session["session_string"] # Store as TD_SESSION_STRING

bridge.start_calls
```

Note:
- `ntgcalls` media engine alone is not enough to connect Telegram calls.
- Telegram signaling/auth still needs an MTProto client (here: Telethon through py-tgcalls).

## Steps to Setup TDJSON:

1. Push a tag (example: `v0.2.1`) or manually run the `Release TDJSON` workflow.
2. Download the zip for your OS from the GitHub Release assets:
   - `tdjson-linux-x64.zip`
   - `tdjson-macos-x64.zip`
   - `tdjson-windows-x64.zip`
3. Extract and copy them into the repo:
   - `Linux: vendor/tdlib/linux/libtdjson.so`
   - `macOS: vendor/tdlib/macos/libtdjson.dylib`
   - `Windows: vendor/tdlib/windows/tdjson.dll`
4. Optional: Set `TDJSON_PATH` if you want to use a custom path.

Note: `GrubY::TDLib::Native` now also auto-detects from `vendor/tdlib/...` paths.

## Examples:

- `example/bot.rb`
- `example/tdlib.rb`
- `example/userbot.rb` (phone/QR login)
