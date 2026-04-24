require_relative "types/user"
require_relative "file_stream"
require_relative "types/message"

module GrubY
  class Context
    attr_reader :update, :api, :session

    def initialize(update, api, session = nil)
      @update = update
      @api = api
      @session = session
    end

    def message
      data = message_payload
      Message.new(data) if data
    end

    def text
      message_payload&.dig("text")
    end

    def chat_id
      message_payload&.dig("chat", "id")
    end

    def from
      data = user_data
      User.new(data) if data
    end

    def poll(question, options)
      @api.send_poll(chat_id, question, options)
    end

    def callback_query
      update["callback_query"]
    end

    def user
      from
    end

    def session_data
      return {} unless @session && user

      @session.get(user.id)
    end

    def set_session(value)
      return unless @session && user

      @session.set(user.id, value)
    end

    def reply(text, keyboard=nil)
      params = {}
      params[:reply_markup] = keyboard if keyboard
      @api.send_message(chat_id, text, **params)
    end

    def answer_callback(text=nil, show_alert: false)
      id = callback_query&.dig("id")
      return unless id

      params = { callback_query_id: id, show_alert: show_alert }
      params[:text] = text if text
      @api.raw("answerCallbackQuery", params)
    end

    def raw(method, params={})
      @api.raw(method, params)
    end

    def command
      t = text
      return nil unless t&.start_with?("/")

      token = t.split(/\s+/, 2).first
      token.sub(%r{^/}, "").split("@", 2).first
    end

    def command_args
      t = text
      return [] unless t

      _, rest = t.split(/\s+/, 2)
      return [] unless rest

      rest.strip.split(/\s+/)
    end

    def file_id
      data = message_payload
      return nil unless data

      if data["photo"]
        data["photo"].last["file_id"]
      elsif data["video"]
        data["video"]["file_id"]
      elsif data["audio"]
        data["audio"]["file_id"]
      elsif data["document"]
        data["document"]["file_id"]
      end
    end

    def download(file_name="file.dat")
      f = api.get_file(file_id)
      api.download_file(f["file_path"], file_name)
      file_name
    end

    private

    def message_payload
      @update["message"] || @update.dig("callback_query", "message")
    end

    def user_data
      @update.dig("message", "from") || @update.dig("callback_query", "from")
    end
  end
end

