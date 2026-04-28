require "json"
require "net/http"
require "uri"
require_relative "retry"

module GrubY
  class API
    class Error < StandardError; end
    METHOD_ALIASES = {
      "set_bot_commands" => "setMyCommands",
      "get_bot_commands" => "getMyCommands",
      "delete_bot_commands" => "deleteMyCommands",
      "set_bot_name" => "setMyName",
      "get_bot_name" => "getMyName",
      "set_bot_info_description" => "setMyDescription",
      "get_bot_info_description" => "getMyDescription",
      "set_bot_info_short_description" => "setMyShortDescription",
      "get_bot_info_short_description" => "getMyShortDescription",
      "set_bot_default_privileges" => "setMyDefaultAdministratorRights",
      "get_bot_default_privileges" => "getMyDefaultAdministratorRights",
      "get_chat_members_count" => "getChatMemberCount",
      "get_chat_photos" => "getUserProfilePhotos",
      "get_chat_audios" => "getUserProfileAudios",
      "set_emoji_status" => "setUserEmojiStatus",
      "get_managed_bot_token" => "getManagedBotToken",
      "replace_managed_bot_token" => "replaceManagedBotToken",
      "ban_chat_member" => "banChatMember",
      "unban_chat_member" => "unbanChatMember",
      "restrict_chat_member" => "restrictChatMember",
      "promote_chat_member" => "promoteChatMember",
      "set_administrator_title" => "setChatAdministratorCustomTitle",
      "set_chat_member_tag" => "setChatMemberTag",
      "set_chat_menu_button" => "setChatMenuButton",
      "get_chat_menu_button" => "getChatMenuButton",
      "send_reaction" => "setMessageReaction",
      "set_message_reaction" => "setMessageReaction",
      "export_chat_invite_link" => "exportChatInviteLink",
      "create_chat_invite_link" => "createChatInviteLink",
      "edit_chat_invite_link" => "editChatInviteLink",
      "revoke_chat_invite_link" => "revokeChatInviteLink",
      "approve_chat_join_request" => "approveChatJoinRequest",
      "decline_chat_join_request" => "declineChatJoinRequest",
      "send_message_draft" => "sendMessageDraft",
      "send_paid_reaction" => "sendPaidReaction",
      "get_user_chat_boosts" => "getUserChatBoosts",
      "get_business_connection" => "getBusinessConnection",
      "forward_media_group" => "forwardMessages",
      "copy_media_group" => "copyMessages"
    }.freeze

    def initialize(token)
      @token = token
      @base = URI("https://api.telegram.org/bot#{token}/")
    end

    def request(method, params = {})
      payload = raw(method, params)
      payload["result"]
    end

    def raw(method, params = {})
      uri = @base + method.to_s
      response = Retry.call { Net::HTTP.post_form(uri, serialize_params(params)) }
      parse_response(response)
    end

    def get_updates(offset = nil, timeout: 30, **opts)
      params = { timeout: timeout }.merge(opts)
      params[:offset] = offset if offset
      request("getUpdates", params)
    end

    def get_file(file_id)
      request("getFile", { file_id: file_id })
    end

    def download_file(file_path, save_as)
      url = URI("https://api.telegram.org/file/bot#{@token}/#{file_path}")
      File.open(save_as, "wb") do |file|
        file.write(Net::HTTP.get(url))
      end
      save_as
    end

    def send_message(chat_id, text, **opts)
      request("sendMessage", { chat_id: chat_id, text: text }.merge(opts))
    end

    def forward_message(chat_id, from_chat_id, message_id, **opts)
      request("forwardMessage", {
        chat_id: chat_id,
        from_chat_id: from_chat_id,
        message_id: message_id
      }.merge(opts))
    end

    def forward_messages(chat_id, from_chat_id, message_ids, **opts)
      request("forwardMessages", {
        chat_id: chat_id,
        from_chat_id: from_chat_id,
        message_ids: message_ids
      }.merge(opts))
    end

    def forward_media_group(chat_id, from_chat_id, message_ids, **opts)
      forward_messages(chat_id, from_chat_id, message_ids, **opts)
    end

    def copy_message(chat_id, from_chat_id, message_id, **opts)
      request("copyMessage", {
        chat_id: chat_id,
        from_chat_id: from_chat_id,
        message_id: message_id
      }.merge(opts))
    end

    def copy_messages(chat_id, from_chat_id, message_ids, **opts)
      request("copyMessages", {
        chat_id: chat_id,
        from_chat_id: from_chat_id,
        message_ids: message_ids
      }.merge(opts))
    end

    def copy_media_group(chat_id, from_chat_id, message_ids, **opts)
      copy_messages(chat_id, from_chat_id, message_ids, **opts)
    end

    def send_photo(chat_id, photo, **opts)
      request("sendPhoto", { chat_id: chat_id, photo: photo }.merge(opts))
    end

    def send_audio(chat_id, audio, **opts)
      request("sendAudio", { chat_id: chat_id, audio: audio }.merge(opts))
    end

    def send_document(chat_id, document, **opts)
      request("sendDocument", { chat_id: chat_id, document: document }.merge(opts))
    end

    def send_video(chat_id, video, **opts)
      request("sendVideo", { chat_id: chat_id, video: video }.merge(opts))
    end

    def send_animation(chat_id, animation, **opts)
      request("sendAnimation", { chat_id: chat_id, animation: animation }.merge(opts))
    end

    def send_voice(chat_id, voice, **opts)
      request("sendVoice", { chat_id: chat_id, voice: voice }.merge(opts))
    end

    def send_video_note(chat_id, video_note, **opts)
      request("sendVideoNote", { chat_id: chat_id, video_note: video_note }.merge(opts))
    end

    def send_sticker(chat_id, sticker, **opts)
      request("sendSticker", { chat_id: chat_id, sticker: sticker }.merge(opts))
    end

    def send_cached_media(chat_id, file_id, **opts)
      request("sendDocument", { chat_id: chat_id, document: file_id }.merge(opts))
    end

    def send_screenshot_notification(chat_id, **opts)
      request("sendScreenshotNotification", { chat_id: chat_id }.merge(opts))
    end

    def send_paid_media(chat_id, star_count, media, **opts)
      request("sendPaidMedia", {
        chat_id: chat_id,
        star_count: star_count,
        media: media
      }.merge(opts))
    end

    def send_media_group(chat_id, media, **opts)
      request("sendMediaGroup", { chat_id: chat_id, media: media }.merge(opts))
    end

    def send_location(chat_id, latitude, longitude, **opts)
      request("sendLocation", {
        chat_id: chat_id,
        latitude: latitude,
        longitude: longitude
      }.merge(opts))
    end

    def send_venue(chat_id, latitude, longitude, title, address, **opts)
      request("sendVenue", {
        chat_id: chat_id,
        latitude: latitude,
        longitude: longitude,
        title: title,
        address: address
      }.merge(opts))
    end

    def send_contact(chat_id, phone_number, first_name, **opts)
      request("sendContact", {
        chat_id: chat_id,
        phone_number: phone_number,
        first_name: first_name
      }.merge(opts))
    end

    def send_poll(chat_id, question, options, **opts)
      request("sendPoll", {
        chat_id: chat_id,
        question: question,
        options: options
      }.merge(opts))
    end

    def send_checklist(chat_id, checklist, business_connection_id:, **opts)
      request("sendChecklist", {
        business_connection_id: business_connection_id,
        chat_id: chat_id,
        checklist: checklist
      }.merge(opts))
    end

    def get_web_app_link_url(**opts)
      request("getWebAppLinkUrl", opts)
    end

    def get_web_app_url(**opts)
      request("getWebAppUrl", opts)
    end

    def open_web_app(**opts)
      request("openWebApp", opts)
    end

    def send_dice(chat_id, **opts)
      request("sendDice", { chat_id: chat_id }.merge(opts))
    end

    def send_message_draft(chat_id, draft_id, text, **opts)
      request("sendMessageDraft", {
        chat_id: chat_id,
        draft_id: draft_id,
        text: text
      }.merge(opts))
    end

    def send_chat_action(chat_id, action, **opts)
      request("sendChatAction", { chat_id: chat_id, action: action }.merge(opts))
    end

    def set_message_reaction(chat_id, message_id, **opts)
      request("setMessageReaction", {
        chat_id: chat_id,
        message_id: message_id
      }.merge(opts))
    end

    def send_reaction(chat_id, message_id, **opts)
      set_message_reaction(chat_id, message_id, **opts)
    end

    def answer_callback_query(callback_query_id, **opts)
      request("answerCallbackQuery", {
        callback_query_id: callback_query_id
      }.merge(opts))
    end

    def answer_callback(callback_query_id, **opts)
      answer_callback_query(callback_query_id, **opts)
    end

    def edit_message_text(chat_id, message_id, text, **opts)
      request("editMessageText", {
        chat_id: chat_id,
        message_id: message_id,
        text: text
      }.merge(opts))
    end

    def delete_message(chat_id, message_id)
      request("deleteMessage", {
        chat_id: chat_id,
        message_id: message_id
      })
    end

    def delete_messages(chat_id, message_ids, **opts)
      request("deleteMessages", {
        chat_id: chat_id,
        message_ids: message_ids
      }.merge(opts))
    end

    def method_missing(name, *args, **kwargs, &block)
      return super if block

      params = {}
      if args.length == 1 && args.first.is_a?(Hash)
        params.merge!(args.first)
      elsif !args.empty?
        return super
      end
      params.merge!(kwargs) unless kwargs.empty?

      request(self.class.camelize_api_method(name), params)
    end

    def respond_to_missing?(_name, _include_private = false)
      true
    end

    def self.escape_markdown_v2(text)
      text.to_s.gsub(/([_\*\[\]\(\)~`>#+\-=|{}.!\\])/, '\\\\\1')
    end

    def self.escape_html(text)
      text.to_s
        .gsub("&", "&amp;")
        .gsub("<", "&lt;")
        .gsub(">", "&gt;")
        .gsub('"', "&quot;")
    end

    def self.camelize_api_method(name)
      alias_name = METHOD_ALIASES[name.to_s]
      return alias_name if alias_name

      parts = name.to_s.split("_")
      return name.to_s if parts.empty?

      parts.first + parts[1..].map(&:capitalize).join
    end

    private

    def serialize_params(params)
      params.each_with_object({}) do |(key, value), out|
        next if value.nil?

        out[key.to_s] = serialize_value(value)
      end
    end

    def serialize_value(value)
      case value
      when Hash, Array
        JSON.generate(value)
      else
        value
      end
    end

    def parse_response(response)
      payload = JSON.parse(response.body)
      return payload if payload["ok"]

      message = payload["description"] || "Unknown Telegram API error"
      raise Error, message
    rescue JSON::ParserError
      raise Error, "Invalid Telegram API response (HTTP #{response.code})"
    end
  end
end
