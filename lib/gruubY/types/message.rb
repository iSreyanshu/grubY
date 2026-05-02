require_relative "base_object"
require_relative "user"
require_relative "chat"
require_relative "message_entity"
require_relative "extra"

module GrubY
  class Message < BaseObject
    fields :message_id, :message_thread_id, :direct_messages_topic, :from,
      :sender_chat, :sender_boost_count, :sender_business_bot, :sender_tag,
      :date, :business_connection_id, :chat, :forward_origin, :is_topic_message,
      :is_automatic_forward, :reply_to_message, :external_reply, :quote,
      :reply_to_story, :reply_to_checklist_task_id, :reply_to_poll_option_id,
      :via_bot, :edit_date, :has_protected_content, :is_from_offline,
      :is_paid_post, :media_group_id, :author_signature, :paid_star_count,
      :text, :entities, :link_preview_options, :suggested_post_info, :effect_id,
      :animation, :audio, :document, :paid_media, :photo, :sticker, :story,
      :video, :video_note, :voice, :caption, :caption_entities,
      :show_caption_above_media, :has_media_spoiler, :checklist, :contact, :dice,
      :game, :poll, :venue, :location, :new_chat_members, :left_chat_member,
      :chat_owner_left, :chat_owner_changed, :new_chat_title, :new_chat_photo,
      :delete_chat_photo, :group_chat_created, :supergroup_chat_created,
      :channel_chat_created, :message_auto_delete_timer_changed,
      :migrate_to_chat_id, :migrate_from_chat_id, :pinned_message, :invoice,
      :successful_payment, :refunded_payment, :users_shared, :chat_shared, :gift,
      :unique_gift, :gift_upgrade_sent, :connected_website,
      :write_access_allowed, :passport_data, :proximity_alert_triggered,
      :boost_added, :chat_background_set, :checklist_tasks_done,
      :checklist_tasks_added, :direct_message_price_changed,
      :forum_topic_created, :forum_topic_edited, :forum_topic_closed,
      :forum_topic_reopened, :general_forum_topic_hidden,
      :general_forum_topic_unhidden, :giveaway_created, :giveaway,
      :giveaway_winners, :giveaway_completed, :managed_bot_created,
      :paid_message_price_changed, :poll_option_added, :poll_option_deleted,
      :suggested_post_approved, :suggested_post_approval_failed,
      :suggested_post_declined, :suggested_post_paid,
      :suggested_post_refunded, :video_chat_scheduled, :video_chat_started,
      :video_chat_ended, :video_chat_participants_invited, :web_app_data,
      :reply_markup

    def initialize(data, api: nil, client: nil)
      super(data, api: api, client: client)
      @from = User.new(@from, api: api, client: client) if @from.is_a?(Hash)
      @chat = Chat.new(@chat, api: api, client: client) if @chat.is_a?(Hash)
      @sender_chat = Chat.new(@sender_chat, api: api, client: client) if @sender_chat.is_a?(Hash)
      @sender_business_bot = User.new(@sender_business_bot, api: api, client: client) if @sender_business_bot.is_a?(Hash)
      @via_bot = User.new(@via_bot, api: api, client: client) if @via_bot.is_a?(Hash)
      @reply_to_message = Message.new(@reply_to_message, api: api, client: client) if @reply_to_message.is_a?(Hash)
      @external_reply = ExternalReplyInfo.new(@external_reply) if @external_reply.is_a?(Hash)
      @quote = TextQuote.new(@quote) if @quote.is_a?(Hash)
      @reply_to_story = Story.new(@reply_to_story) if @reply_to_story.is_a?(Hash)
      @entities = Array(@entities).map { |e| MessageEntity.new(e) }
      @caption_entities = Array(@caption_entities).map { |e| MessageEntity.new(e) }
      @photo = Array(@photo).map { |p| PhotoSize.new(p) }
      @animation = Animation.new(@animation) if @animation.is_a?(Hash)
      @audio = Audio.new(@audio) if @audio.is_a?(Hash)
      @document = Document.new(@document) if @document.is_a?(Hash)
      @story = Story.new(@story) if @story.is_a?(Hash)
      @video = Video.new(@video) if @video.is_a?(Hash)
      @video_note = VideoNote.new(@video_note) if @video_note.is_a?(Hash)
      @voice = Voice.new(@voice) if @voice.is_a?(Hash)
      @paid_media = PaidMediaInfo.new(@paid_media) if @paid_media.is_a?(Hash)
      @contact = Contact.new(@contact) if @contact.is_a?(Hash)
      @dice = Dice.new(@dice) if @dice.is_a?(Hash)
      @poll = Poll.new(@poll) if @poll.is_a?(Hash)
      @new_chat_members = Array(@new_chat_members).map { |u| User.new(u, api: api, client: client) }
      @left_chat_member = User.new(@left_chat_member, api: api, client: client) if @left_chat_member.is_a?(Hash)
    end

    def reply(text = nil, **opts)
      call_api("sendMessage", { chat_id: chat_id!, text: text.to_s, reply_to_message_id: message_id }.merge(opts))
    end

    def reply_text(text = nil, **opts)
      reply(text, **opts)
    end

    def answer(text = nil, **opts)
      reply(text, **opts)
    end

    def edit_text(text, **opts)
      call_api("editMessageText", { chat_id: chat_id!, message_id: message_id, text: text.to_s }.merge(opts))
    end

    alias edit edit_text

    def edit_caption(caption, **opts)
      call_api("editMessageCaption", { chat_id: chat_id!, message_id: message_id, caption: caption.to_s }.merge(opts))
    end

    def edit_media(media, **opts)
      call_api("editMessageMedia", { chat_id: chat_id!, message_id: message_id, media: media }.merge(opts))
    end

    def edit_checklist(checklist, **opts)
      call_api("editMessageChecklist", { chat_id: chat_id!, message_id: message_id, checklist: checklist }.merge(opts))
    end

    def edit_reply_markup(reply_markup = nil, **opts)
      call_api("editMessageReplyMarkup", { chat_id: chat_id!, message_id: message_id, reply_markup: reply_markup }.merge(opts))
    end

    def edit_live_location(latitude:, longitude:, **opts)
      call_api("editMessageLiveLocation", { chat_id: chat_id!, message_id: message_id, latitude: latitude, longitude: longitude }.merge(opts))
    end

    def stop_live_location(**opts)
      call_api("stopMessageLiveLocation", { chat_id: chat_id!, message_id: message_id }.merge(opts))
    end

    def forward(to_chat_id:, from_chat_id: chat_id!, **opts)
      call_api("forwardMessage", { chat_id: to_chat_id, from_chat_id: from_chat_id, message_id: message_id }.merge(opts))
    end

    def copy(to_chat_id:, from_chat_id: chat_id!, **opts)
      call_api("copyMessage", { chat_id: to_chat_id, from_chat_id: from_chat_id, message_id: message_id }.merge(opts))
    end

    def copy_media_group(to_chat_id:, from_chat_id: chat_id!, **opts)
      call_api("copyMessages", { chat_id: to_chat_id, from_chat_id: from_chat_id, message_ids: [message_id] }.merge(opts))
    end

    def delete(**opts)
      call_api("deleteMessage", { chat_id: chat_id!, message_id: message_id }.merge(opts))
    end

    def react(reaction:, is_big: false)
      call_api("setMessageReaction", { chat_id: chat_id!, message_id: message_id, reaction: reaction, is_big: is_big })
    end

    def retract_vote(**opts)
      call_api("stopPoll", { chat_id: chat_id!, message_id: message_id }.merge(opts))
    end

    def vote(option_ids, **opts)
      call_api("sendPoll", { chat_id: chat_id!, options: option_ids }.merge(opts))
    end

    def pin(**opts)
      call_api("pinChatMessage", { chat_id: chat_id!, message_id: message_id }.merge(opts))
    end

    def unpin(**opts)
      call_api("unpinChatMessage", { chat_id: chat_id!, message_id: message_id }.merge(opts))
    end

    def read
      call_raw_api("readChatHistory", { chat_id: chat_id! })
    end

    def view
      call_raw_api("viewMessages", { chat_id: chat_id!, message_ids: [message_id] })
    end

    def pay(**opts)
      call_raw_api("sendPaymentForm", { chat_id: chat_id!, message_id: message_id }.merge(opts))
    end

    def accept_gift_purchase_offer(**opts)
      call_raw_api("processGiftPurchaseOffer", { message_id: message_id, accept: true }.merge(opts))
    end

    def reject_gift_purchase_offer(**opts)
      call_raw_api("processGiftPurchaseOffer", { message_id: message_id, accept: false }.merge(opts))
    end

    def summarize(summary_language_code: "en")
      call_raw_api("summarizeMessage", { chat_id: chat_id!, message_id: message_id, summary_language_code: summary_language_code })
    end

    def fix_text_with_ai(**opts)
      call_raw_api("fixTextWithAi", { chat_id: chat_id!, message_id: message_id }.merge(opts))
    end

    def compose_text_with_ai(**opts)
      call_raw_api("composeTextWithAi", { chat_id: chat_id!, message_id: message_id }.merge(opts))
    end

    def reply_inline_bot_result(result_id:, query_id:, **opts)
      call_raw_api("sendInlineBotResult", { chat_id: chat_id!, query_id: query_id, result_id: result_id }.merge(opts))
    end

    def answer_inline_bot_result(result_id:, query_id:, **opts)
      reply_inline_bot_result(result_id: result_id, query_id: query_id, **opts)
    end

    def get_media_group
      return nil if media_group_id.to_s.empty?

      call_raw_api("getMediaGroup", { chat_id: chat_id!, message_id: message_id })
    end

    def reply_chat_action(action)
      call_api("sendChatAction", { chat_id: chat_id!, action: action })
    end

    def click
      raise NotImplementedError, "click() requires callback query context"
    end

    def download(file_name = "file.dat")
      file_id = resolve_file_id
      raise ArgumentError, "message has no downloadable media" if file_id.nil?

      f = call_api("getFile", { file_id: file_id })
      call_raw_api("getFile", { file_id: file_id }) unless f
      file_path = f && f["file_path"]
      raise ArgumentError, "file_path not found for file_id=#{file_id}" if file_path.to_s.empty?

      @api.download_file(file_path, file_name)
      file_name
    end

    SENDERS = {
      animation: "sendAnimation",
      audio: "sendAudio",
      contact: "sendContact",
      document: "sendDocument",
      game: "sendGame",
      invoice: "sendInvoice",
      location: "sendLocation",
      media_group: "sendMediaGroup",
      photo: "sendPhoto",
      poll: "sendPoll",
      dice: "sendDice",
      sticker: "sendSticker",
      venue: "sendVenue",
      video: "sendVideo",
      video_note: "sendVideoNote",
      voice: "sendVoice",
      paid_media: "sendPaidMedia",
      cached_media: "sendDocument",
      checklist: "sendChecklist"
    }.freeze

    SENDERS.each do |name, method_name|
      define_method("reply_#{name}") do |payload = nil, **opts|
        params = { chat_id: chat_id!, reply_to_message_id: message_id }.merge(opts)
        params = attach_payload(name, params, payload)
        call_api(method_name, params)
      end

      define_method("answer_#{name}") do |payload = nil, **opts|
        public_send("reply_#{name}", payload, **opts)
      end
    end

    private

    def chat_id!
      @chat&.id || self["chat"]&.dig("id") || raise(ArgumentError, "message has no chat id")
    end

    def attach_payload(kind, params, payload)
      case kind
      when :animation, :audio, :document, :photo, :sticker, :video, :video_note, :voice
        params.merge(kind => payload)
      when :contact
        params.merge(payload.is_a?(Hash) ? payload : {})
      when :game
        params.merge(game_short_name: payload)
      when :invoice
        params.merge(payload.is_a?(Hash) ? payload : {})
      when :location
        params.merge(payload.is_a?(Hash) ? payload : {})
      when :media_group
        params.merge(media: payload)
      when :poll
        params.merge(payload.is_a?(Hash) ? payload : {})
      when :venue
        params.merge(payload.is_a?(Hash) ? payload : {})
      when :paid_media
        params.merge(payload.is_a?(Hash) ? payload : {})
      when :cached_media
        params.merge(document: payload)
      when :checklist
        params.merge(checklist: payload)
      else
        params
      end
    end

    def resolve_file_id
      return @document.file_id if @document&.respond_to?(:file_id)
      return @audio.file_id if @audio&.respond_to?(:file_id)
      return @video.file_id if @video&.respond_to?(:file_id)
      return @voice.file_id if @voice&.respond_to?(:file_id)
      return @animation.file_id if @animation&.respond_to?(:file_id)
      return @photo.last.file_id if @photo.is_a?(Array) && @photo.last&.respond_to?(:file_id)

      nil
    end
  end
end
