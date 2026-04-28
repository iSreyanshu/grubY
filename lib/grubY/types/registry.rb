require_relative "base_object"

module GrubY
  module TypeRegistry
    TYPE_NAMES = %w[
      AcceptedGiftTypes Birthday BusinessConnection BusinessIntro BusinessRecipients BusinessWeeklyOpen BusinessWorkingHours
      Username VerificationStatus ChatPhoto ChatMember ChatPermissions ChatAdministratorRights ChatInviteLink ChatAdminWithInviteLinks
      ChatEvent ChatEventFilter ChatMemberUpdated ChatJoiner Dialog Restriction EmojiStatus FailedToAddMember Folder GroupCallMember
      ChatColor FoundContacts PrivacyRule StoriesStealthMode UserRating BotVerification BusinessBotRights ChatSettings
      GlobalPrivacySettings HistoryCleared BusinessMessage MessageOriginChannel MessageOriginChat MessageOriginHiddenUser
      MessageOriginImport MessageOriginUser MessageOrigin Photo PollOptionAdded PollOptionDeleted Thumbnail StrippedThumbnail
      AvailableEffect ExternalReplyInfo FactCheck FormattedText ForumTopic ForumTopicClosed ForumTopicCreated ForumTopicEdited
      ForumTopicReopened GeneralForumTopicHidden GeneralForumTopicUnhidden Contact CraftGiftResult CraftGiftResultSuccess
      CraftGiftResultFail Location ManagedBotCreated MaskPosition MediaArea Venue Sticker Game WebPage ProximityAlertTriggered
      PollOption Dice Reaction RestrictionReason Gift VideoChatScheduled VideoChatStarted VideoChatEnded VideoChatMembersInvited
      PhoneCallStarted PhoneCallEnded WebAppData MessageReactions ChatReactions MyBoost BoostsStatus Giveaway InputChecklistTask
      GiveawayCreated GiveawayPrizeStars GiveawayCompleted GiveawayWinners Invoice LinkPreviewOptions GiftCollection PremiumGiftCode
      GiftPurchaseLimit GiftResaleParameters GiftResalePrice GiftResalePriceStar GiftResalePriceTon GiftUpgradePreview
      GiftUpgradePrice GiftUpgradeVariants CheckedGiftCode ChecklistTask ChecklistTasksAdded ChecklistTasksDone Checklist
      RefundedPayment ReplyParameters SuccessfulPayment SuggestedPostParameters SuggestedPostInfo SuggestedPostPaid
      SuggestedPostPrice SuggestedPostPriceStar SuggestedPostPriceTon SuggestedPostApprovalFailed SuggestedPostApproved
      SuggestedPostDeclined SuggestedPostRefunded TextQuote PaidMediaInfo PaidMediaPreview PaidMessagesRefunded PaidReactor
      PaidMessagesPriceChanged DirectMessagePriceChanged DirectMessagesTopic PaymentForm PaymentOption SavedCredentials PaymentResult
      ChatBoost ChatOwnerChanged ChatOwnerLeft ChatHasProtectedContentToggled ChatHasProtectedContentDisableRequested
      ContactRegistered ScreenshotTaken StarAmount WriteAccessAllowed GiftAttribute StoryView GiftedPremium ChatBackground ChatTheme
      GiftedStars GiftedTon UpgradedGiftValueInfo UpgradedGiftAttributeId UpgradedGiftPurchaseOffer UpgradedGiftPurchaseOfferRejected
      UpgradedGiftAttributeIdModel UpgradedGiftAttributeIdSymbol UpgradedGiftAttributeIdBackdrop UpgradedGiftAttributeRarity
      UpgradedGiftAttributeRarityPerMille UpgradedGiftAttributeRarityUncommon UpgradedGiftAttributeRarityRare
      UpgradedGiftAttributeRarityEpic UpgradedGiftAttributeRarityLegendary UpgradedGiftOriginalDetails InputChatPhoto
      InputChatPhotoPrevious InputChatPhotoStatic InputChatPhotoAnimation AuctionBid AuctionRound AuctionState AuctionStateActive
      AuctionStateFinished GiftAuctionState GiftAuction ReplyKeyboardMarkup KeyboardButton ReplyKeyboardRemove
      InlineKeyboardMarkup InlineKeyboardButton LoginUrl ForceReply GameHighScore CallbackGame WebAppInfo MenuButton
      MenuButtonCommands MenuButtonWebApp MenuButtonDefault SentWebAppMessage KeyboardButtonRequestChat
      KeyboardButtonRequestManagedBot KeyboardButtonRequestUsers KeyboardButtonPollType ManagedBotUpdated OrderInfo
      MessageReactionUpdated MessageReactionCountUpdated ChatBoostUpdated ShippingOption PurchasedPaidMedia ChatShared UsersShared
      BotCommand BotCommandScope BotCommandScopeDefault BotCommandScopeAllPrivateChats BotCommandScopeAllGroupChats
      BotCommandScopeAllChatAdministrators BotCommandScopeChat BotCommandScopeChatAdministrators BotCommandScopeChatMember
      InlineQueryResult InlineQueryResultCachedAudio InlineQueryResultCachedDocument InlineQueryResultCachedAnimation
      InlineQueryResultCachedPhoto InlineQueryResultCachedSticker InlineQueryResultCachedVideo InlineQueryResultCachedVoice
      InlineQueryResultArticle InlineQueryResultAudio InlineQueryResultContact InlineQueryResultDocument InlineQueryResultAnimation
      InlineQueryResultLocation InlineQueryResultPhoto InlineQueryResultVenue InlineQueryResultVideo InlineQueryResultVoice
      ChosenInlineResult ActiveSessions FirebaseAuthenticationSettings FirebaseAuthenticationSettingsAndroid
      FirebaseAuthenticationSettingsIos PhoneNumberAuthenticationSettings SentCode TermsOfService InputChecklist
      InputContactMessageContent InputCredentials InputCredentialsApplePay InputCredentialsGooglePay InputCredentialsNew
      InputCredentialsSaved InputInvoice InputInvoiceMessage InputInvoiceMessageContent InputInvoiceName
      InputLocationMessageContent InputMedia InputMediaAnimation InputMediaAudio InputMediaDocument InputMediaPhoto
      InputMediaVideo InputMessageContent InputPhoneContact InputPollOption InputPrivacyRule InputPrivacyRuleAllowAll
      InputPrivacyRuleAllowBots InputPrivacyRuleAllowChats InputPrivacyRuleAllowCloseFriends InputPrivacyRuleAllowContacts
      InputPrivacyRuleAllowPremium InputPrivacyRuleAllowUsers InputPrivacyRuleDisallowAll InputPrivacyRuleDisallowBots
      InputPrivacyRuleDisallowChats InputPrivacyRuleDisallowContacts InputPrivacyRuleDisallowUsers InputTextMessageContent
      InputVenueMessageContent
    ].freeze

    module_function

    def install!
      TYPE_NAMES.each do |type_name|
        next if GrubY.const_defined?(type_name)

        klass = Class.new(GrubY::BaseObject)
        GrubY.const_set(type_name, klass)
      end
    end
  end
end

GrubY::TypeRegistry.install!
