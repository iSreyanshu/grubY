module GrubY
  module WebApp
    module_function

    def info(url:)
      {
        web_app: {
          url: url.to_s
        }
      }
    end

    def inline_button(text:, url:)
      {
        text: text.to_s,
        web_app: {
          url: url.to_s
        }
      }
    end
  end
end
