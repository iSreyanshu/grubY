# GrubY

A Ruby Telegram toolkit with:

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

### GitHub Build Se TDJSON Kaise Lo

## NTgCalls Voice Chat Bridge (Join VC + Play Audio)

GrubY includes a bridge for Telegram voice chats via `py-tgcalls` + `ntgcalls`.
Backend is now `Telethon` (no Pyrogram).

Files:

- `lib/grubY/ntgcalls.rb`
- `lib/grubY/ntgcalls/bridge.py`
- `example/ntgcalls_demo.rb`
- `example/requirements-ntgcalls.txt`

### Install Python deps

```bash
python -m pip install -r example/requirements-ntgcalls.txt
```

### Environment

- `TD_API_ID` (required)
- `TD_API_HASH` (required)
- `TD_SESSION_STRING` (Telethon string session; recommended)
- `VC_CHAT_ID` (required for demo)
- `VC_AUDIO` (required; local file path or URL)

### Run Demo

```bash
ruby example/ntgcalls_demo.rb
```

The demo will:

1. Start the NTgCalls bridge
2. Join/start VC in `VC_CHAT_ID`
3. Play `VC_AUDIO`
4. Accept runtime commands: `pause`, `resume`, `mute`, `unmute`, `participants`, `leave`, `quit`

### Full Method Access

Use `GrubY::NTgCalls::Bridge#call` for additional py-tgcalls methods:

```ruby
bridge.call("record", args: [chat_id, "recorded.raw"])
bridge.call("time", args: [chat_id])
```

PyTgCalls-like Ruby usage via alias:

```ruby
rbt = GrubY::NTgCalls::RBtgCalls.new(api_id: ..., api_hash: ..., session_string: ...)
rbt.start
rbt.play(chat_id: -100123, stream: "song.mp3")
rbt.pause(-100123)
```

Direct NTgCalls binding methods:

```ruby
bridge.ntg_call("calls")
bridge.ntg_call("cpu_usage")
```

Method discovery:

```ruby
bridge.pytgcalls_methods
bridge.ntgcalls_methods
```

Note:
- `ntgcalls` media engine alone is not enough to connect Telegram calls.
- Telegram signaling/auth still needs an MTProto client (here: Telethon through py-tgcalls).

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
