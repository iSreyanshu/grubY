module GrubY
  class Keyboard
    class << self
      def inline(rows)
        { inline_keyboard: rows }
      end

      def reply(rows, resize_keyboard: true, one_time_keyboard: false, is_persistent: false)
        {
          keyboard: rows,
          resize_keyboard: resize_keyboard,
          one_time_keyboard: one_time_keyboard,
          is_persistent: is_persistent
        }
      end

      def button(text, data = nil)
        {
          text: text.to_s,
          callback_data: data.to_s
        }
      end

      def url_button(text, url)
        {
          text: text.to_s,
          url: url.to_s
        }
      end

      def web_app_button(text, url)
        {
          text: text.to_s,
          web_app: {
            url: url.to_s
          }
        }
      end

      def switch_inline_button(text, query:, in_current_chat: false)
        key = in_current_chat ? :switch_inline_query_current_chat : :switch_inline_query
        {
          text: text.to_s,
          key => query.to_s
        }
      end
    end
  end
end
