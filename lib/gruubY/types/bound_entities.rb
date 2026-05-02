require_relative "base_object"

module GrubY
  class CallbackQuery < BaseObject
    fields :id, :from, :message, :inline_message_id, :chat_instance, :data, :game_short_name

    def answer(text = nil, show_alert: false, **opts)
      call_api("answerCallbackQuery", { callback_query_id: id, text: text, show_alert: show_alert }.merge(opts))
    end

    def edit_message_text(text, **opts)
      edit_payload("editMessageText", { text: text }.merge(opts))
    end

    def edit_message_caption(caption, **opts)
      edit_payload("editMessageCaption", { caption: caption }.merge(opts))
    end

    def edit_message_media(media, **opts)
      edit_payload("editMessageMedia", { media: media }.merge(opts))
    end

    def edit_message_reply_markup(reply_markup = nil, **opts)
      edit_payload("editMessageReplyMarkup", { reply_markup: reply_markup }.merge(opts))
    end

    private

    def edit_payload(method, payload)
      if inline_message_id.to_s.empty?
        msg = message || {}
        call_api(method, payload.merge(chat_id: msg.dig("chat", "id"), message_id: msg["message_id"]))
      else
        call_api(method, payload.merge(inline_message_id: inline_message_id))
      end
    end
  end

  class InlineQuery < BaseObject
    fields :id, :from, :query, :offset, :chat_type, :location

    def answer(results, **opts)
      call_api("answerInlineQuery", { inline_query_id: id, results: results }.merge(opts))
    end
  end

  class PreCheckoutQuery < BaseObject
    fields :id, :from, :currency, :total_amount, :invoice_payload, :shipping_option_id, :order_info

    def answer(ok:, error_message: nil)
      call_api("answerPreCheckoutQuery", { pre_checkout_query_id: id, ok: ok, error_message: error_message }.compact)
    end
  end

  class ShippingQuery < BaseObject
    fields :id, :from, :invoice_payload, :shipping_address

    def answer(ok:, shipping_options: nil, error_message: nil)
      call_api("answerShippingQuery", {
        shipping_query_id: id,
        ok: ok,
        shipping_options: shipping_options,
        error_message: error_message
      }.compact)
    end
  end

  class ChatJoinRequest < BaseObject
    fields :chat, :from, :user_chat_id, :date, :bio, :invite_link

    def approve
      call_api("approveChatJoinRequest", { chat_id: chat_id!, user_id: user_id! })
    end

    def decline
      call_api("declineChatJoinRequest", { chat_id: chat_id!, user_id: user_id! })
    end

    private

    def chat_id!
      chat.is_a?(Hash) ? chat["id"] : chat&.id
    end

    def user_id!
      from.is_a?(Hash) ? from["id"] : from&.id
    end
  end

  class Story < BaseObject
    fields :id, :chat, :date

    def reply_text(text, **opts)
      chat_id = chat.is_a?(Hash) ? chat["id"] : chat&.id
      call_api("sendMessage", { chat_id: chat_id, text: text.to_s }.merge(opts))
    end

    alias reply reply_text
    alias answer reply_text

    STORY_SENDERS = {
      animation: "sendAnimation",
      audio: "sendAudio",
      cached_media: "sendDocument",
      media_group: "sendMediaGroup",
      photo: "sendPhoto",
      sticker: "sendSticker",
      video: "sendVideo",
      video_note: "sendVideoNote",
      voice: "sendVoice"
    }.freeze

    STORY_SENDERS.each do |name, method_name|
      define_method("reply_#{name}") do |payload = nil, **opts|
        cid = chat.is_a?(Hash) ? chat["id"] : chat&.id
        params = { chat_id: cid }.merge(opts)
        params = if name == :media_group
                   params.merge(media: payload)
                 elsif name == :cached_media
                   params.merge(document: payload)
                 else
                   params.merge(name => payload)
                 end
        call_api(method_name, params)
      end

      define_method("answer_#{name}") do |payload = nil, **opts|
        public_send("reply_#{name}", payload, **opts)
      end
    end

    def delete
      call_raw_api("deleteStories", { story_ids: [id] })
    end

    def edit_media(media, **opts)
      call_raw_api("editStoryMedia", { story_id: id, media: media }.merge(opts))
    end

    def edit_caption(caption, **opts)
      call_raw_api("editStoryCaption", { story_id: id, caption: caption.to_s }.merge(opts))
    end

    def edit_privacy(privacy, **opts)
      call_raw_api("editStoryPrivacy", { story_id: id, privacy: privacy }.merge(opts))
    end

    def react(reaction)
      call_raw_api("setStoryReaction", { story_id: id, reaction: reaction })
    end

    def forward(chat_id:)
      call_raw_api("forwardStory", { story_id: id, chat_id: chat_id })
    end

    def download(file_name = "story.dat")
      call_raw_api("downloadFile", { story_id: id, file_name: file_name })
    end

    def read
      call_raw_api("readChatStories", { story_id: id })
    end

    def view
      call_raw_api("viewStories", { story_ids: [id] })
    end
  end

  class Folder < BaseObject
    fields :id, :name

    def delete
      call_raw_api("deleteFolder", { folder_id: id })
    end

    def edit(**opts)
      call_raw_api("editFolder", { folder_id: id }.merge(opts))
    end
  end

  class ActiveSession < BaseObject
    fields :hash

    def reset
      call_raw_api("resetSession", { session_hash: self["hash"] || hash })
    end
  end

  class Gift < BaseObject
    fields :id, :owned_gift_id

    def show
      call_raw_api("showGift", gift_payload)
    end

    def hide
      call_raw_api("hideGift", gift_payload)
    end

    def convert
      call_raw_api("convertGiftToStars", gift_payload)
    end

    def upgrade(**opts)
      call_raw_api("upgradeGift", gift_payload.merge(opts))
    end

    def transfer(user_id:, **opts)
      call_raw_api("transferGift", gift_payload.merge(user_id: user_id).merge(opts))
    end

    def wear
      call_raw_api("setProfileGift", gift_payload)
    end

    def buy(**opts)
      call_raw_api("sendGift", gift_payload.merge(opts))
    end

    def send(user_id:, **opts)
      call_raw_api("sendGift", gift_payload.merge(user_id: user_id).merge(opts))
    end

    def get_auction_state
      call_raw_api("getGiftAuctionState", gift_payload)
    end

    def send_purchase_offer(**opts)
      call_raw_api("sendGiftPurchaseOffer", gift_payload.merge(opts))
    end

    private

    def gift_payload
      { gift_id: self["id"] || id, owned_gift_id: self["owned_gift_id"] || owned_gift_id }.compact
    end
  end

  class Animation < BaseObject
    def add_to_gifs
      file_id = self["file_id"] || dig("file_id")
      call_raw_api("addToGifs", { file_id: file_id })
    end
  end
end
