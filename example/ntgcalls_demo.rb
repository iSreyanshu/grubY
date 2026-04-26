require_relative "../lib/grubY"
require "json"

# Usage:
# TD_API_ID=12345 TD_API_HASH=xxxx TD_SESSION_STRING=xxxx \
# VC_CHAT_ID=-1001234567890 VC_AUDIO=./song.mp3 ruby example/ntgcalls_demo.rb
#
# Notes:
# VC_AUDIO can be a local path or direct media URL.
# For user accounts, provide TD_SESSION_STRING (Telethon String Ssession).

api_id = ENV["TD_API_ID"]&.to_i
api_hash = ENV["TD_API_HASH"]
session_string = ENV["TD_SESSION_STRING"]
chat_id = ENV["VC_CHAT_ID"]&.to_i
audio = ENV["VC_AUDIO"]

abort("Missing TD_API_ID/TD_API_HASH") unless api_id && api_hash
abort("Missing VC_CHAT_ID") unless chat_id
abort("Missing VC_AUDIO") if audio.to_s.empty?

bridge = GrubY::NTgCalls::Bridge.new(
  api_id: api_id,
  api_hash: api_hash,
  session_string: session_string,
  session_name: ENV.fetch("NTGCALLS_SESSION_NAME", "gruby_ntgcalls")
)

begin
  bridge.start
  puts "[NTgCalls] Connected"

  bridge.play(chat_id: chat_id, stream: audio, auto_start: true)
  puts "[NTgCalls] Joined voice chat and started playback"

  puts "Commands: pause, resume, mute, unmute, participants, methods, ntgmethods, leave, quit"
  loop do
    print "> "
    cmd = STDIN.gets.to_s.strip.downcase

    case cmd
    when "pause"
      bridge.pause(chat_id: chat_id)
      puts "paused"
    when "resume"
      bridge.resume(chat_id: chat_id)
      puts "resumed"
    when "mute"
      bridge.mute(chat_id: chat_id)
      puts "muted"
    when "unmute"
      bridge.unmute(chat_id: chat_id)
      puts "unmuted"
    when "participants"
      data = bridge.get_participants(chat_id: chat_id)
      puts data.to_json
    when "methods"
      data = bridge.pytgcalls_methods
      puts data.to_json
    when "ntgmethods"
      data = bridge.ntgcalls_methods
      puts data.to_json
    when "leave"
      bridge.leave_call(chat_id: chat_id)
      puts "left call"
    when "quit", "exit"
      break
    else
      puts "unknown command"
    end
  end
ensure
  bridge.stop
end
