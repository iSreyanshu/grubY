module GrubY
  module Enums
    DEFINITIONS = {
      BlockList: %w[main stories],
      BusinessSchedule: %w[always offline custom],
      ButtonStyle: %w[default primary danger success],
      ChatAction: %w[typing upload_photo record_video upload_video record_voice upload_voice upload_document choose_sticker find_location record_video_note upload_video_note],
      ChatEventAction: %w[create edit delete pin unpin join leave invite restrict promote],
      ChatJoinType: %w[by_link by_request by_invite by_username],
      ChatMemberStatus: %w[creator administrator member restricted left kicked],
      ChatMembersFilter: %w[recent administrators contacts bots banned restricted search],
      ChatType: %w[private bot group supergroup channel direct forum],
      ClientPlatform: %w[ruby linux windows macos android ios web],
      FolderColor: %w[blue cyan green orange pink purple red yellow],
      MessageEntityType: %w[mention hashtag cashtag bot_command url email phone_number bold italic underline strikethrough spoiler code pre text_link text_mention custom_emoji],
      MessageMediaType: %w[text photo video animation audio voice video_note document sticker contact location venue poll dice game story paid_media],
      MessageOriginType: %w[user hidden_user chat channel],
      MessageServiceType: %w[new_chat_members left_chat_member new_chat_title new_chat_photo delete_chat_photo group_chat_created supergroup_chat_created channel_chat_created migrate_to_chat_id migrate_from_chat_id pinned_message game_score video_chat_started video_chat_ended video_chat_members_invited successful_payment],
      MessagesFilter: %w[empty photo video document url gif voice music chat_photo phone_call round_video video_note voice_note photo_video mention unread mention_me pinned],
      NextCodeType: %w[sms call flash_call missed_call fragment app],
      PaidReactionPrivacy: %w[anonymous default sender],
      ParseMode: %w[markdown markdown_v2 html],
      PhoneCallDiscardReason: %w[missed disconnect hangup busy],
      PhoneNumberCodeType: %w[sms call flash_call missed_call fragment app],
      PollType: %w[regular quiz],
      PrivacyKey: %w[last_seen phone_number profile_photo forwards calls p2p_invite link_in_bio birthday gifts voice_messages about],
      ProfileColor: %w[blue cyan green orange pink purple red yellow],
      ProfileTab: %w[profile gifts media links files voice],
      ReplyColor: %w[blue cyan green orange pink purple red yellow],
      SentCodeType: %w[sms call flash_call missed_call fragment app firebase email],
      StoriesPrivacyRules: %w[everyone contacts close_friends selected],
      UserStatus: %w[online offline recently last_week last_month long_time_ago],
      UpgradedGiftOrigin: %w[upgrade gift_code transfer craft purchase],
      GiftAttributeType: %w[model symbol backdrop rarity id original_details],
      MediaAreaType: %w[venue location suggested_reaction link weather],
      PrivacyRuleType: %w[allow_all allow_contacts allow_users allow_chats allow_close_friends allow_premium disallow_all disallow_contacts disallow_users disallow_chats disallow_bots],
      GiftForResaleOrder: %w[newest oldest price_asc price_desc rarity_asc rarity_desc],
      GiftPurchaseOfferState: %w[pending accepted rejected expired canceled],
      GiftType: %w[regular upgraded unique collectible],
      PaymentFormType: %w[invoice stars ton gift_upgrade],
      StickerType: %w[regular mask custom_emoji],
      MaskPointType: %w[forehead eyes mouth chin],
      SuggestedPostRefundReason: %w[not_published rejected timeout canceled],
      SuggestedPostState: %w[pending approved declined paid refunded failed]
    }.freeze

    DEFINITIONS.each do |enum_name, values|
      enum_module = Module.new
      values.each do |value|
        const_name = value.upcase.gsub(/[^A-Z0-9]+/, "_")
        enum_module.const_set(const_name, value)
      end
      const_set(enum_name, enum_module)
    end

    module GroupCallUpdateType
      UPDATE_GROUP_CALL = "updateGroupCall"
      UPDATE_GROUP_CALL_PARTICIPANTS = "updateGroupCallParticipants"
      UPDATE_GROUP_CALL_SIGNALING_DATA = "updateGroupCallSignalingData"
    end
  end
end
