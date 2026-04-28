module GrubY
  module Bound
    module_function

    def bind(ctx)
      {
        send: ->(text) { ctx.reply(text) },
        raw: ->(method, params = {}) { ctx.raw(method, params) },
        inline_keyboard: ->(rows) { GrubY::Keyboard.inline(rows) },
        webapp_button: ->(text, url) { GrubY::WebApp.inline_button(text: text, url: url) }
      }
    end
  end
end
