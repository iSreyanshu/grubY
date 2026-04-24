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

    def initialize(data)
      super(data)
      @from = User.new(@from) if @from.is_a?(Hash)
      @chat = Chat.new(@chat) if @chat.is_a?(Hash)
      @sender_chat = Chat.new(@sender_chat) if @sender_chat.is_a?(Hash)
      @sender_business_bot = User.new(@sender_business_bot) if @sender_business_bot.is_a?(Hash)
      @via_bot = User.new(@via_bot) if @via_bot.is_a?(Hash)
      @reply_to_message = Message.new(@reply_to_message) if @reply_to_message.is_a?(Hash)
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
      @new_chat_members = Array(@new_chat_members).map { |u| User.new(u) }
      @left_chat_member = User.new(@left_chat_member) if @left_chat_member.is_a?(Hash)
    end
  end
end
