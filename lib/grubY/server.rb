require "sinatra/base"
require "json"
require_relative "../../config/config"

module GrubY
  class Server < Sinatra::Base
    def initialize(bot)
      super()
      @bot = bot
    end

    post Config::WEBHOOK_PATH do
      data = JSON.parse(request.body.read)
      @bot.process_update(data)
      "ok"
    end
  end
end
