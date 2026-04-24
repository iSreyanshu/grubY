require "net/http"

module GrubY
  class Media
    def initialize(token)
      @base = "https://api.telegram.org/bot#{token}/"
    end

    def send_photo(chat_id, file)
      post_file("sendPhoto", "photo", chat_id, file)
    end

    def send_video(chat_id, file)
      post_file("sendVideo", "video", chat_id, file)
    end

    def send_audio(chat_id, file)
      post_file("sendAudio", "audio", chat_id, file)
    end

    def post_file(method, field_name, chat_id, file)
      uri = URI(@base + method)

      File.open(file, "rb") do |io|
        req = Net::HTTP::Post.new(uri)
        form_data = [
          ["chat_id", chat_id],
          [field_name, io]
        ]

        req.set_form form_data, "multipart/form-data"
        Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
          http.request(req)
        end
      end
    end
  end
end

