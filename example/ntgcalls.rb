require_relative "../lib/grubY"

# Usage:
# TD_USER_SESSION='<base64>' \
# VC_CHAT='@YourGroupOrChannel' \
# VC_AUDIO=./song.mp3 \
# ruby example/ntgcalls.rb
#
# Optional:
# TDJSON_PATH=/path/to/libtdjson.so
# NTGCALLS_PATH=/path/to/libntgcalls.so
# VC_INVITE_HASH=xxxx

td_user_session = ENV["TD_USER_SESSION"].to_s
chat = ENV["VC_CHAT"].to_s
audio = ENV["VC_AUDIO"].to_s

abort("Missing TD_USER_SESSION") if td_user_session.empty?
abort("Missing VC_CHAT (chat id or @username)") if chat.empty?
abort("Missing VC_AUDIO") if audio.empty?

bot = GrubY::NTgCalls::MusicBot.new(
  td_user_session: td_user_session,
  tdjson_path: ENV["TDJSON_PATH"],
  ntgcalls_path: ENV["NTGCALLS_PATH"],
  phone_number: ENV["TD_PHONE"]
)

begin
  bot.start
  result = bot.join_and_play(
    chat: chat,
    audio: audio,
    invite_hash: ENV.fetch("VC_INVITE_HASH", "")
  )
  puts "[NTgCalls] Joined chat #{result[:chat_id]} and started playback."

  puts "Commands: pause, resume, mute, unmute, time, cpu, stop, quit"
  loop do
    print "> "
    cmd = STDIN.gets.to_s.strip.downcase

    case cmd
    when "pause"
      bot.pause
      puts "paused"
    when "resume"
      bot.resume
      puts "resumed"
    when "mute"
      bot.mute
      puts "muted"
    when "unmute"
      bot.unmute
      puts "unmuted"
    when "time"
      puts bot.time
    when "cpu"
      puts bot.cpu_usage
    when "stop"
      bot.stop_call
      puts "stopped"
    when "quit", "exit"
      break
    else
      puts "unknown command!"
    end
  end
ensure
  bot.stop
end
