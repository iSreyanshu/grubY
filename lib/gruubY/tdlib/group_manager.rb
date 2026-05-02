module GrubY
  module TDLib
    class GroupManager
      def initialize(client)
        @client = client
      end

      def ban_chat_member(chat_id:, member_id:, banned_until_date: 0, revoke_messages: true)
        @client.banChatMember(
          chat_id: chat_id,
          member_id: member_id,
          banned_until_date: banned_until_date,
          revoke_messages: revoke_messages
        )
      end

      def unban_chat_member(chat_id:, member_id:)
        @client.unbanChatMember(chat_id: chat_id, member_id: member_id)
      end

      def set_chat_title(chat_id:, title:)
        @client.setChatTitle(chat_id: chat_id, title: title)
      end

      def set_chat_description(chat_id:, description:)
        @client.setChatDescription(chat_id: chat_id, description: description)
      end

      def set_slow_mode(chat_id:, delay:)
        @client.setChatSlowModeDelay(chat_id: chat_id, slow_mode_delay: delay)
      end

      def pin_chat_message(chat_id:, message_id:, disable_notification: false)
        @client.pinChatMessage(
          chat_id: chat_id,
          message_id: message_id,
          disable_notification: disable_notification
        )
      end

      def unpin_chat_message(chat_id:, message_id: nil)
        @client.unpinChatMessage(chat_id: chat_id, message_id: message_id)
      end

      def leave_chat(chat_id:)
        @client.leaveChat(chat_id: chat_id)
      end

      def get_chat_member(chat_id:, member_id:)
        @client.getChatMember(chat_id: chat_id, member_id: member_id)
      end

      def get_chat(chat_id:)
        @client.getChat(chat_id: chat_id)
      end
    end
  end
end
