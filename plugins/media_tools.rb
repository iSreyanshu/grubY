require "shellwords"

def self.register(bot)
  bot.on(:message) do |ctx|
    next unless ctx.file_id

    file = ctx.download("input.dat")
    safe_file = Shellwords.escape(file)
    system("ffmpeg -i #{safe_file} output.mp3")

    ctx.reply("Processed file..")
  end
end
