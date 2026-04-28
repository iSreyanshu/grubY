## GrubY

A Ruby Telegram wrapper with:

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
client.on(:message, GrubY::Filters.command("start")) { |ctx| ctx.reply("Heya; Started!") }
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

## NTgCalls Native (Raw Ruby)

GrubY now uses direct Ruby + C bindings for `ntgcalls` (no Python bridge).

example:

- `example/ntgcalls.rb`

### Environment

- `TD_USER_SESSION` (required; generated via `example/generate_user_session.rb`)
- `NTGCALLS_PATH` (optional; absolute/custom path to shared library)
- `VC_CHAT` (required; numeric chat id or `@username`)
- `VC_AUDIO` (required; local file path or URL)
- `VC_INVITE_HASH` (optional; invite hash for restricted voice chats)

### Run Demo

```bash
ruby example/ntgcalls.rb
```

### Direct Ruby Usage

```ruby
bot = GrubY::NTgCalls::MusicBot.new(
  td_user_session: ENV.fetch("TD_USER_SESSION"),
  tdjson_path: ENV["TDJSON_PATH"],
  ntgcalls_path: ENV["NTGCALLS_PATH"]
)

bot.start
bot.join_and_play(chat: "@mychat", audio: "song.mp3")
bot.pause
bot.resume
bot.mute
bot.unmute
bot.stop_call
bot.stop
```

Note:
- `ntgcalls` is a media engine.
- This demo performs signaling/auth through TDLib raw calls plus NTgCalls media engine.

## Telegram User Session String (Ruby)

Generate a reusable TDLib user session string:

```bash
TD_API_ID=12345 TD_API_HASH=xxxx ruby example/generate_user_session.rb
```

After login, script prints:

```bash
TD_USER_SESSION=<base64>
```

Reuse:

```ruby
cfg = GrubY::TDLib::UserSession.client_kwargs(ENV.fetch("TD_USER_SESSION"))
client = GrubY::TDLib::Client.new(**cfg, tdjson_path: ENV["TDJSON_PATH"])
client.run
```

## Framework Helpers

Enums:

```ruby
GrubY::Enums::ParseMode::MARKDOWN_V2
GrubY::Enums::ChatAction::TYPING
GrubY::Enums::GroupCallUpdateType::UPDATE_GROUP_CALL
```

Inline keyboard + WebApp:

```ruby
markup = GrubY::Keyboard.inline([
  [GrubY::Keyboard.button("Ping", "ping:1")],
  [GrubY::Keyboard.web_app_button("Open App", "https://example.com/app")]
])
client.send_message(chat_id, "Menu", reply_markup: markup)
```

Bound + Raw:

```ruby
bound = GrubY::Bound.bind(ctx)
bound[:send].call("hello")
bound[:raw].call("getMe")
GrubY::Raw.td_call!(td_client, { "@type": "getMe" })
```

Modern-style method coverage:

```ruby
# Client/API support snake_case dynamic methods similar to modern libraries
client.send_screenshot_notification(chat_id: 123)
client.get_web_app_url(bot_user_id: 123, url: "https://example.com")
client.compose_text_with_ai(text: "fix this")
```

Bound objects:

```ruby
client.on(:message) do |ctx|
  msg = ctx.message
  msg.reply_text("pong")
  msg.reply_photo("file_id_or_url")
  msg.edit_text("updated")
  msg.react(reaction: [{ type: "emoji", emoji: "👍" }])
end
```

Dynamic type registry:

```ruby
# Hundreds of Telegram/modern types are available as BaseObject subclasses
u = GrubY::VerificationStatus.new("is_verified" => true)
p u.to_h
```

## Enumerations

All requested enum groups are available under `GrubY::Enums`:

- `BlockList`, `BusinessSchedule`, `ButtonStyle`, `ChatAction`, `ChatEventAction`, `ChatJoinType`
- `ChatMemberStatus`, `ChatMembersFilter`, `ChatType`, `ClientPlatform`, `FolderColor`
- `MessageEntityType`, `MessageMediaType`, `MessageOriginType`, `MessageServiceType`, `MessagesFilter`
- `NextCodeType`, `PaidReactionPrivacy`, `ParseMode`, `PhoneCallDiscardReason`, `PhoneNumberCodeType`, `PollType`
- `PrivacyKey`, `ProfileColor`, `ProfileTab`, `ReplyColor`, `SentCodeType`, `StoriesPrivacyRules`, `UserStatus`
- `UpgradedGiftOrigin`, `GiftAttributeType`, `MediaAreaType`, `PrivacyRuleType`, `GiftForResaleOrder`
- `GiftPurchaseOfferState`, `GiftType`, `PaymentFormType`, `StickerType`, `MaskPointType`
- `SuggestedPostRefundReason`, `SuggestedPostState`

Example:

```ruby
GrubY::Enums::ParseMode::MARKDOWN_V2
GrubY::Enums::ChatType::SUPERGROUP
GrubY::Enums::ChatMemberStatus::ADMINISTRATOR
```

## Decorators

Pyrogram-style decorators are supported on `GrubY::Client`:

- `on_message`, `on_edited_message`, `on_business_message`, `on_edited_business_message`
- `on_deleted_messages`, `on_deleted_business_messages`
- `on_message_reaction_count`, `on_message_reaction`
- `on_business_connection`, `on_story`, `on_callback_query`, `on_chat_boost`
- `on_chat_join_request`, `on_chat_member_updated`, `on_chosen_inline_result`, `on_inline_query`
- `on_poll`, `on_pre_checkout_query`, `on_purchased_paid_media`, `on_shipping_query`, `on_user_status`
- `on_start`, `on_stop`, `on_connect`, `on_disconnect`, `on_error`, `on_managed_bot`, `on_raw_update`

Example:

```ruby
client.on_message(GrubY::Filters.command("start")) do |app, message|
  message.reply_text("pong")
end

client.on_callback_query do |app, cq|
  cq.answer("ok")
end
```

## Handlers

`GrubY::Handlers` classes are available for `add_handler()`:

- `MessageHandler`, `EditedMessageHandler`, `DeletedMessagesHandler`
- `BusinessMessageHandler`, `EditedBusinessMessageHandler`, `DeletedBusinessMessagesHandler`
- `BusinessConnectionHandler`, `CallbackQueryHandler`, `ChatBoostHandler`, `ChatJoinRequestHandler`
- `ChatMemberUpdatedHandler`, `ChosenInlineResultHandler`, `InlineQueryHandler`
- `MessageReactionCountHandler`, `MessageReactionHandler`, `PollHandler`
- `PreCheckoutQueryHandler`, `PurchasedPaidMediaHandler`, `ShippingQueryHandler`
- `StoryHandler`, `UserStatusHandler`
- `StartHandler`, `StopHandler`, `ConnectHandler`, `DisconnectHandler`
- `ErrorHandler`, `ManagedBotUpdatedHandler`, `RawUpdateHandler`

Example:

```ruby
handler = GrubY::Handlers::MessageHandler.new(proc { |app, message| message.reply_text("hi") })
client.add_handler(handler)
```

## Update Filters

Ruby `GrubY::Filters` now supports:

- `create(func:, name:, **kwargs)` custom filter creator
- Boolean composition: `&`, `|`, `~`
- Update filters: `all`, `me`, `bot`, `sender_chat`, `incoming`, `outgoing`
- Content filters: `text`, `reply`, `forwarded`, `caption`, `audio`, `document`, `photo`, `sticker`, `animation`, `video`, `voice`, `video_note`, `contact`, `location`, `venue`, `web_page`, `poll`, `dice`, `quote`, `media_spoiler`, `story`, `media_group`
- Chat filters: `private`, `group`, `channel`, `direct`, `forum`
- Service/media filters: `service`, `media`, plus specific service keys (`new_chat_members`, `pinned_message`, `video_chat_started`, etc.)
- Parameterized filters: `command(...)`, `regex(...)`, `user(...)`, `chat(...)`, `topic(...)`

Example:

```ruby
f = GrubY::Filters.command(%w[start help]) & GrubY::Filters.private
client.on_message(f) { |app, msg| msg.reply_text("ok") }
```

Raw group-call objects:

```ruby
igc = GrubY::RawTypes.input_group_call(id: 1, access_hash: 2)
peer = GrubY::RawTypes.input_peer_self
json = GrubY::RawTypes.to_data_json({ ufrag: "x" })
join = GrubY::RawTypes.join_group_call(call: igc, params: json, join_as: peer)
leave = GrubY::RawTypes.leave_group_call(call: igc, source: 123)
```

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
- `example/ntgcalls.rb`
- `example/generate_user_session.rb`
- `example/tdlib.rb`
- `example/userbot.rb` (phone/QR login)
