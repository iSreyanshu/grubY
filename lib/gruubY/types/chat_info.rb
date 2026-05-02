require_relative "base_object"
require_relative "chat"

module GrubY
  class ChatFullInfo < BaseObject
    fields :id, :type, :title, :username, :first_name, :last_name, :is_forum,
      :is_direct_messages, :accent_color_id, :max_reaction_count, :photo,
      :active_usernames, :birthdate, :business_intro, :business_location,
      :business_opening_hours, :personal_chat, :parent_chat,
      :available_reactions, :background_custom_emoji_id,
      :profile_accent_color_id, :profile_background_custom_emoji_id,
      :emoji_status_custom_emoji_id, :emoji_status_expiration_date, :bio,
      :has_private_forwards, :has_restricted_voice_and_video_messages,
      :join_to_send_messages, :join_by_request, :description, :invite_link,
      :pinned_message, :permissions, :accepted_gift_types,
      :can_send_paid_media, :slow_mode_delay, :unrestrict_boost_count,
      :message_auto_delete_time, :has_aggressive_anti_spam_enabled,
      :has_hidden_members, :has_protected_content, :has_visible_history,
      :sticker_set_name, :can_set_sticker_set,
      :custom_emoji_sticker_set_name, :linked_chat_id, :location, :rating,
      :first_profile_audio, :unique_gift_colors, :paid_message_star_count

    def initialize(data)
      super(data)
      @personal_chat = Chat.new(@personal_chat) if @personal_chat.is_a?(Hash)
      @parent_chat = Chat.new(@parent_chat) if @parent_chat.is_a?(Hash)
    end
  end

  ChatInfo = ChatFullInfo
end
