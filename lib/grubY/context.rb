require_relative "types/user"
require_relative "file_stream"
require_relative "types/message"
require_relative "types/bound_entities"
require_relative "types/base_object"

module GrubY
  class Context
    attr_reader :update, :api, :session

    def initialize(update, api, session = nil)
      @update = update
      @api = api
      @session = session
    end

    def message
      data = primary_message_payload
      Message.new(data, api: @api) if data
    end

    def edited_message
      data = @update["edited_message"]
      Message.new(data, api: @api) if data
    end

    def business_message
      data = @update["business_message"]
      Message.new(data, api: @api) if data
    end

    def edited_business_message
      data = @update["edited_business_message"]
      Message.new(data, api: @api) if data
    end

    def deleted_messages
      list = @update["deleted_messages"]
      Array(list).map { |m| Message.new(m, api: @api) }
    end

    def deleted_business_messages
      list = @update["deleted_business_messages"]
      Array(list).map { |m| Message.new(m, api: @api) }
    end

    def text
      primary_message_payload&.dig("text")
    end

    def chat_id
      primary_message_payload&.dig("chat", "id")
    end

    def from
      data = user_data
      User.new(data, api: @api) if data
    end

    def poll(question, options)
      @api.send_poll(chat_id, question, options)
    end

    def callback_query
      data = update["callback_query"]
      CallbackQuery.new(data, api: @api) if data
    end

    def inline_query
      data = update["inline_query"]
      InlineQuery.new(data, api: @api) if data
    end

    def pre_checkout_query
      data = update["pre_checkout_query"]
      PreCheckoutQuery.new(data, api: @api) if data
    end

    def shipping_query
      data = update["shipping_query"]
      ShippingQuery.new(data, api: @api) if data
    end

    def chat_join_request
      data = update["chat_join_request"]
      ChatJoinRequest.new(data, api: @api) if data
    end

    def business_connection
      data = @update["business_connection"]
      wrap_type("BusinessConnection", data)
    end

    def message_reaction_count
      data = @update["message_reaction_count"] || @update["message_reaction_count_updated"]
      wrap_type("MessageReactionCountUpdated", data)
    end

    def message_reaction
      data = @update["message_reaction"] || @update["message_reaction_updated"]
      wrap_type("MessageReactionUpdated", data)
    end

    def chat_boost
      data = @update["chat_boost"] || @update["chat_boost_updated"]
      wrap_type("ChatBoostUpdated", data)
    end

    def chat_member_updated
      data = @update["chat_member_updated"] || @update["chat_member"]
      wrap_type("ChatMemberUpdated", data)
    end

    def chosen_inline_result
      data = @update["chosen_inline_result"]
      wrap_type("ChosenInlineResult", data)
    end

    def poll_update
      data = @update["poll"]
      wrap_type("Poll", data)
    end

    def purchased_paid_media
      data = @update["purchased_paid_media"]
      wrap_type("PurchasedPaidMedia", data)
    end

    def story_update
      data = @update["story"]
      Story.new(data, api: @api) if data
    end

    def user_status
      data = @update["user_status"] || @update["user"]
      User.new(data, api: @api) if data
    end

    def managed_bot_updated
      data = @update["managed_bot_updated"] || @update["managed_bot"]
      wrap_type("ManagedBotUpdated", data)
    end

    def error_payload
      @update["error"]
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

    def reply(text, keyboard = nil)
      params = {}
      params[:reply_markup] = keyboard if keyboard
      @api.send_message(chat_id, text, **params)
    end

    def answer_callback(text = nil, show_alert: false)
      id = callback_query&.id
      return unless id

      params = { callback_query_id: id, show_alert: show_alert }
      params[:text] = text if text
      @api.raw("answerCallbackQuery", params)
    end

    def raw(method, params = {})
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
      data = primary_message_payload
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

    def download(file_name = "file.dat")
      f = api.get_file(file_id)
      api.download_file(f["file_path"], file_name)
      file_name
    end

    private

    def primary_message_payload
      @update["message"] || @update.dig("callback_query", "message")
    end

    def user_data
      @update.dig("message", "from") || @update.dig("callback_query", "from")
    end

    def wrap_type(type_name, data)
      return nil unless data
      return data unless GrubY.const_defined?(type_name)

      klass = GrubY.const_get(type_name)
      return data unless klass <= GrubY::BaseObject

      klass.new(data, api: @api)
    end
  end
end
