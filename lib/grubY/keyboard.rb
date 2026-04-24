require "json"

module GrubY
  class Keyboard
    def self.inline(buttons)
      {
        inline_keyboard: buttons
      }.to_json
    end

    def self.button(text, data)
      {
        text: text,
        callback_data: data
      }
    end
  end
end

